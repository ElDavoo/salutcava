import 'dart:math';

import 'protocol.dart';
import 'scheduler.dart';

typedef Clock = DateTime Function();

class SimulationConfig {
  const SimulationConfig({
    required this.peopleCount,
    required this.maxConcurrent,
    required this.schedulerMode,
  }) : assert(peopleCount >= 2 && peopleCount <= 20),
       assert(maxConcurrent >= 1 && maxConcurrent <= 5);

  final int peopleCount;
  final int maxConcurrent;
  final SchedulerMode schedulerMode;

  int get totalPairs => peopleCount * (peopleCount - 1) ~/ 2;
}

class SimulationController {
  SimulationController({
    required SimulationConfig config,
    PairScheduler? scheduler,
    Clock? clock,
    Random? random,
  }) : _config = config,
       _clock = clock ?? DateTime.now,
       _random = random ?? Random(),
       _scheduler = scheduler ?? const DeterministicPairScheduler() {
    if (scheduler == null) {
      _scheduler = buildScheduler(config.schedulerMode, random: _random);
    }
    _initialize();
  }

  SimulationConfig _config;
  final Clock _clock;
  Random _random;
  PairScheduler _scheduler;

  late Map<PairId, PairProgress> _pairStates;
  final List<BatchExecution> _history = <BatchExecution>[];
  final Map<PairId, bool> _preferContinueStep2 = <PairId, bool>{};
  final List<_ActiveConversation> _activeConversations =
      <_ActiveConversation>[];
  int _totalTurns = 0;
  DateTime? _startedAt;
  DateTime? _finishedAt;

  late SimulationSnapshot _snapshot;

  SimulationSnapshot get snapshot => _snapshot;

  void updateConfig(SimulationConfig newConfig, {Random? random}) {
    _config = newConfig;
    if (random != null) {
      _random = random;
    }
    _scheduler = buildScheduler(newConfig.schedulerMode, random: _random);
    _initialize();
  }

  void restart({Random? random}) {
    if (random != null) {
      _random = random;
    }
    _scheduler = buildScheduler(_config.schedulerMode, random: _random);
    _initialize();
  }

  BatchExecution? advance() {
    if (_finishedAt != null) {
      return null;
    }

    _startedAt ??= _clock();
    final selectedCandidates = _selectCandidatesForSlots(
      _buildWaveCandidates(),
      _config.maxConcurrent,
    );

    if (selectedCandidates.isEmpty) {
      _finishedAt = _clock();
      _snapshot = _buildSnapshot();
      return null;
    }

    final turns = <MessageTurn>[];
    final pairs = <PairId>[];
    final phases = <BatchType>{};
    final completed = <_ActiveConversation>[];

    for (final candidate in selectedCandidates) {
      final conversation =
          candidate.conversation ??
          _startConversation(candidate.pair, candidate.phase);

      final turn = _turnForPair(
        conversation.pair,
        conversation.phase,
        conversation.nextMessageIndex,
      );
      turns.add(turn);
      pairs.add(conversation.pair);
      phases.add(conversation.phase);

      conversation.nextMessageIndex++;
      if (conversation.nextMessageIndex >= _turnCountFor(conversation.phase)) {
        completed.add(conversation);
      }
    }

    for (final conversation in completed) {
      _completeConversation(conversation);
      _activeConversations.remove(conversation);
    }

    _totalTurns += turns.length;
    final execution = BatchExecution(
      type: _executionTypeFor(phases),
      pairs: pairs,
      turns: turns,
    );
    _history.add(execution);

    if (_activeConversations.isEmpty &&
        _pairStates.values.every((state) => state == PairProgress.complete)) {
      _finishedAt = _clock();
    }

    _snapshot = _buildSnapshot(lastBatch: execution);
    return execution;
  }

  void _initialize() {
    _pairStates = <PairId, PairProgress>{
      for (var left = 0; left < _config.peopleCount; left++)
        for (var right = left + 1; right < _config.peopleCount; right++)
          PairId(left, right): PairProgress.notStarted,
    };
    _history.clear();
    _preferContinueStep2.clear();
    _activeConversations.clear();
    _totalTurns = 0;
    _startedAt = null;
    _finishedAt = null;
    _snapshot = _buildSnapshot();
  }

  SimulationSnapshot _buildSnapshot({BatchExecution? lastBatch}) {
    final displayBatchType = _activeConversations.isNotEmpty
        ? _executionTypeFor(
            _activeConversations.map((conv) => conv.phase).toSet(),
          )
        : _predictNextBatchType();
    final elapsed = _startedAt == null
        ? null
        : (_finishedAt ?? _clock()).difference(_startedAt!);

    return SimulationSnapshot(
      peopleCount: _config.peopleCount,
      maxConcurrent: _config.maxConcurrent,
      nextBatchType: displayBatchType,
      pairStates: _pairStates,
      totalTurns: _totalTurns,
      history: List<BatchExecution>.unmodifiable(_history),
      lastBatch: lastBatch ?? (_history.isEmpty ? null : _history.last),
      startedAt: _startedAt,
      finishedAt: _finishedAt,
      elapsed: elapsed,
    );
  }

  List<_ConversationCandidate> _buildWaveCandidates() {
    final candidates = <_ConversationCandidate>[];

    final orderedOngoing = _orderPairs(
      _activeConversations.map((conversation) => conversation.pair).toList(),
    );
    final ongoingByPair = <PairId, _ActiveConversation>{
      for (final conversation in _activeConversations)
        conversation.pair: conversation,
    };
    for (final pair in orderedOngoing) {
      final conversation = ongoingByPair[pair]!;
      candidates.add(
        _ConversationCandidate(
          pair: pair,
          phase: conversation.phase,
          priority: 5,
          rank: candidates.length,
          conversation: conversation,
        ),
      );
    }

    void addCandidateGroup({
      required List<PairId> pairs,
      required BatchType phase,
      required int priority,
    }) {
      final filtered = pairs
          .where((pair) => !_isPairActive(pair))
          .toList(growable: false);

      final ordered = _orderPairs(filtered);
      for (final pair in ordered) {
        candidates.add(
          _ConversationCandidate(
            pair: pair,
            phase: phase,
            priority: priority,
            rank: candidates.length,
          ),
        );
      }
    }

    addCandidateGroup(
      pairs: _eligibleContinueStep2Pairs(),
      phase: BatchType.step2,
      priority: 4,
    );
    addCandidateGroup(
      pairs: _eligibleStep1Pairs(),
      phase: BatchType.step1,
      priority: 6,
    );
    addCandidateGroup(
      pairs: _eligibleWaitingStep2Pairs(),
      phase: BatchType.step2,
      priority: 3,
    );

    return candidates;
  }

  _ActiveConversation _startConversation(PairId pair, BatchType phase) {
    final conversation = _ActiveConversation(pair: pair, phase: phase);
    _activeConversations.add(conversation);
    return conversation;
  }

  List<PairId> _orderPairs(List<PairId> pairs) {
    if (pairs.length <= 1) {
      return pairs;
    }

    final remaining = List<PairId>.from(pairs);
    final ordered = <PairId>[];

    while (remaining.isNotEmpty) {
      final picked = _scheduler.selectPairs(
        candidates: remaining,
        maxConcurrent: 1,
      );
      if (picked.isEmpty) {
        ordered.addAll(remaining);
        break;
      }
      final pair = picked.first;
      ordered.add(pair);
      remaining.remove(pair);
    }

    return ordered;
  }

  List<_ConversationCandidate> _selectCandidatesForSlots(
    List<_ConversationCandidate> candidates,
    int remainingSlots,
  ) {
    if (remainingSlots <= 0 || candidates.isEmpty) {
      return const <_ConversationCandidate>[];
    }

    final people = <int>{
      for (final candidate in candidates) ...[
        candidate.pair.first,
        candidate.pair.second,
      ],
    };
    if (people.length < 2) {
      return const <_ConversationCandidate>[];
    }

    final peopleList = people.toList()..sort();
    final localIndex = <int, int>{
      for (var i = 0; i < peopleList.length; i++) peopleList[i]: i,
    };

    final edgesByPerson = List<List<_CandidateEdge>>.generate(
      peopleList.length,
      (_) => <_CandidateEdge>[],
    );

    for (final candidate in candidates) {
      var left = localIndex[candidate.pair.first]!;
      var right = localIndex[candidate.pair.second]!;
      if (left > right) {
        final temp = left;
        left = right;
        right = temp;
      }
      edgesByPerson[left].add(
        _CandidateEdge(otherPersonIndex: right, candidate: candidate),
      );
    }

    final fullMask = (1 << peopleList.length) - 1;
    final memo = <int, _CandidateSelection>{};

    _CandidateSelection search(int mask, int slots) {
      if (slots == 0 || !_hasAtLeastTwoBits(mask)) {
        return const _CandidateSelection.empty();
      }

      final key = (mask << 3) | slots;
      final cached = memo[key];
      if (cached != null) {
        return cached;
      }

      final person = _lowestSetBitIndex(mask);
      final maskWithoutPerson = mask & ~(1 << person);

      var best = search(maskWithoutPerson, slots);

      for (final edge in edgesByPerson[person]) {
        final otherBit = 1 << edge.otherPersonIndex;
        if ((maskWithoutPerson & otherBit) == 0) {
          continue;
        }

        final tail = search(maskWithoutPerson & ~otherBit, slots - 1);
        final candidateResult = tail.withCandidate(edge.candidate);
        if (_isBetterSelection(candidateResult, best)) {
          best = candidateResult;
        }
      }

      memo[key] = best;
      return best;
    }

    final selected = search(fullMask, remainingSlots);
    final ordered = List<_ConversationCandidate>.from(selected.candidates)
      ..sort((left, right) => left.rank.compareTo(right.rank));
    return ordered;
  }

  bool _isBetterSelection(
    _CandidateSelection candidate,
    _CandidateSelection current,
  ) {
    if (candidate.count != current.count) {
      return candidate.count > current.count;
    }
    if (candidate.priority != current.priority) {
      return candidate.priority > current.priority;
    }
    return _compareRanks(candidate.ranks, current.ranks) < 0;
  }

  int _compareRanks(List<int> left, List<int> right) {
    final length = min(left.length, right.length);
    for (var i = 0; i < length; i++) {
      final comparison = left[i].compareTo(right[i]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return left.length.compareTo(right.length);
  }

  bool _hasAtLeastTwoBits(int mask) {
    return mask != 0 && (mask & (mask - 1)) != 0;
  }

  int _lowestSetBitIndex(int mask) {
    final lowestBit = mask & -mask;
    return lowestBit.bitLength - 1;
  }

  bool _isPairActive(PairId pair) {
    return _activeConversations.any(
      (conversation) => conversation.pair == pair,
    );
  }

  void _completeConversation(_ActiveConversation conversation) {
    switch (conversation.phase) {
      case BatchType.step1:
        _pairStates[conversation.pair] = PairProgress.step1Done;
        _preferContinueStep2[conversation.pair] = _random.nextBool();
      case BatchType.step2:
        _pairStates[conversation.pair] = PairProgress.complete;
        _preferContinueStep2.remove(conversation.pair);
      case BatchType.mixed:
        throw StateError('Mixed phase cannot be an active conversation.');
    }
  }

  BatchType _predictNextBatchType() {
    if (_activeConversations.isNotEmpty) {
      return _executionTypeFor(
        _activeConversations.map((conversation) => conversation.phase).toSet(),
      );
    }

    final hasStep1 = _eligibleStep1Pairs().isNotEmpty;
    final hasContinueStep2 = _eligibleContinueStep2Pairs().isNotEmpty;
    final hasWaitingStep2 = _eligibleWaitingStep2Pairs().isNotEmpty;

    if (hasStep1 && (hasContinueStep2 || hasWaitingStep2)) {
      return BatchType.mixed;
    }
    if (hasStep1) {
      return BatchType.step1;
    }
    if (hasContinueStep2 || hasWaitingStep2) {
      return BatchType.step2;
    }
    return BatchType.step1;
  }

  BatchType _executionTypeFor(Set<BatchType> phases) {
    if (phases.length == 1) {
      return phases.first;
    }
    if (phases.isEmpty) {
      return BatchType.step1;
    }
    return BatchType.mixed;
  }

  List<PairId> _eligibleStep1Pairs() {
    return _pairStates.entries
        .where((entry) => entry.value == PairProgress.notStarted)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  List<PairId> _eligibleContinueStep2Pairs() {
    return _pairStates.entries
        .where(
          (entry) =>
              entry.value == PairProgress.step1Done &&
              (_preferContinueStep2[entry.key] ?? false),
        )
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  List<PairId> _eligibleWaitingStep2Pairs() {
    return _pairStates.entries
        .where(
          (entry) =>
              entry.value == PairProgress.step1Done &&
              !(_preferContinueStep2[entry.key] ?? false),
        )
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  MessageTurn _turnForPair(PairId pair, BatchType batchType, int messageIndex) {
    final first = pair.first;
    final second = pair.second;

    switch (batchType) {
      case BatchType.step1:
        switch (messageIndex) {
          case 0:
            return MessageTurn(
              from: first,
              to: second,
              text: 'Salut',
              phase: batchType,
            );
          case 1:
            return MessageTurn(
              from: second,
              to: first,
              text: 'Salut',
              phase: batchType,
            );
          default:
            throw StateError(
              'Invalid message index for salut phase: $messageIndex',
            );
        }
      case BatchType.step2:
        switch (messageIndex) {
          case 0:
            return MessageTurn(
              from: first,
              to: second,
              text: 'Ça va ?',
              phase: batchType,
            );
          case 1:
            return MessageTurn(
              from: second,
              to: first,
              text: 'Ça va, et toi ?',
              phase: batchType,
            );
          case 2:
            return MessageTurn(
              from: first,
              to: second,
              text: 'Ouais, ça va.',
              phase: batchType,
            );
          default:
            throw StateError(
              'Invalid message index for ça-va phase: $messageIndex',
            );
        }
      case BatchType.mixed:
        throw StateError('Mixed phase has no direct turn sequence.');
    }
  }

  int _turnCountFor(BatchType type) {
    switch (type) {
      case BatchType.step1:
        return 2;
      case BatchType.step2:
        return 3;
      case BatchType.mixed:
        throw StateError('Mixed phase does not have a fixed turn count.');
    }
  }
}

class _ConversationCandidate {
  const _ConversationCandidate({
    required this.pair,
    required this.phase,
    required this.priority,
    required this.rank,
    this.conversation,
  });

  final PairId pair;
  final BatchType phase;
  final int priority;
  final int rank;
  final _ActiveConversation? conversation;
}

class _CandidateEdge {
  const _CandidateEdge({
    required this.otherPersonIndex,
    required this.candidate,
  });

  final int otherPersonIndex;
  final _ConversationCandidate candidate;
}

class _CandidateSelection {
  const _CandidateSelection({
    required this.candidates,
    required this.ranks,
    required this.priority,
  });

  const _CandidateSelection.empty()
    : candidates = const <_ConversationCandidate>[],
      ranks = const <int>[],
      priority = 0;

  final List<_ConversationCandidate> candidates;
  final List<int> ranks;
  final int priority;

  int get count => candidates.length;

  _CandidateSelection withCandidate(_ConversationCandidate candidate) {
    final nextCandidates = List<_ConversationCandidate>.from(candidates)
      ..add(candidate);
    final nextRanks = List<int>.from(ranks)
      ..add(candidate.rank)
      ..sort();
    return _CandidateSelection(
      candidates: nextCandidates,
      ranks: nextRanks,
      priority: priority + candidate.priority,
    );
  }
}

class _ActiveConversation {
  _ActiveConversation({required this.pair, required this.phase});

  final PairId pair;
  final BatchType phase;
  int nextMessageIndex = 0;
}
