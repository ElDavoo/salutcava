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
  BatchType? _activeBatchType;
  List<PairId> _activeBatchPairs = const <PairId>[];
  int _activeMessageIndex = 0;
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

    if (_activeBatchType == null || _activeBatchPairs.isEmpty) {
      final nextBatch = _selectNextBatch();
      if (nextBatch == null) {
        _finishedAt = _clock();
        _snapshot = _buildSnapshot();
        return null;
      }

      _activeBatchType = nextBatch.type;
      _activeBatchPairs = nextBatch.pairs;
      _activeMessageIndex = 0;
    }

    final activeBatchType = _activeBatchType!;
    final turns = _activeBatchPairs
        .map((pair) => _turnForPair(pair, activeBatchType, _activeMessageIndex))
        .toList(growable: false);

    _totalTurns += turns.length;
    final execution = BatchExecution(
      type: activeBatchType,
      pairs: _activeBatchPairs,
      turns: turns,
    );
    _history.add(execution);

    _activeMessageIndex++;
    if (_activeMessageIndex >= _turnCountFor(activeBatchType)) {
      _completeActiveBatch(activeBatchType, _activeBatchPairs);
      _activeBatchType = null;
      _activeBatchPairs = const <PairId>[];
      _activeMessageIndex = 0;

      if (_pairStates.values.every((state) => state == PairProgress.complete)) {
        _finishedAt = _clock();
      }
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
    _activeBatchType = null;
    _activeBatchPairs = const <PairId>[];
    _activeMessageIndex = 0;
    _totalTurns = 0;
    _startedAt = null;
    _finishedAt = null;
    _snapshot = _buildSnapshot();
  }

  SimulationSnapshot _buildSnapshot({BatchExecution? lastBatch}) {
    final displayBatchType = _activeBatchType ?? _predictNextBatchType();
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

  _BatchSelection? _selectNextBatch() {
    final continueStep2Pairs = _eligibleContinueStep2Pairs();
    if (continueStep2Pairs.isNotEmpty) {
      return _buildSelection(BatchType.step2, continueStep2Pairs);
    }

    final step1Pairs = _eligibleStep1Pairs();
    if (step1Pairs.isNotEmpty) {
      return _buildSelection(BatchType.step1, step1Pairs);
    }

    final delayedStep2Pairs = _eligibleWaitingStep2Pairs();
    if (delayedStep2Pairs.isNotEmpty) {
      return _buildSelection(BatchType.step2, delayedStep2Pairs);
    }

    return null;
  }

  _BatchSelection _buildSelection(BatchType type, List<PairId> candidates) {
    final selected = _scheduler.selectPairs(
      candidates: candidates,
      maxConcurrent: _config.maxConcurrent,
    );
    final pairsToRun = selected.isEmpty ? <PairId>[candidates.first] : selected;
    return _BatchSelection(
      type: type,
      pairs: List<PairId>.unmodifiable(pairsToRun),
    );
  }

  void _completeActiveBatch(BatchType type, List<PairId> pairs) {
    switch (type) {
      case BatchType.step1:
        for (final pair in pairs) {
          _pairStates[pair] = PairProgress.step1Done;
          _preferContinueStep2[pair] = _random.nextBool();
        }
      case BatchType.step2:
        for (final pair in pairs) {
          _pairStates[pair] = PairProgress.complete;
          _preferContinueStep2.remove(pair);
        }
    }
  }

  BatchType _predictNextBatchType() {
    if (_eligibleContinueStep2Pairs().isNotEmpty) {
      return BatchType.step2;
    }
    if (_eligibleStep1Pairs().isNotEmpty) {
      return BatchType.step1;
    }
    if (_eligibleWaitingStep2Pairs().isNotEmpty) {
      return BatchType.step2;
    }
    return BatchType.step1;
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
            return MessageTurn(from: first, to: second, text: 'Salut');
          case 1:
            return MessageTurn(from: second, to: first, text: 'Salut');
          default:
            throw StateError(
              'Invalid message index for salut phase: $messageIndex',
            );
        }
      case BatchType.step2:
        switch (messageIndex) {
          case 0:
            return MessageTurn(from: first, to: second, text: 'Ça va ?');
          case 1:
            return MessageTurn(
              from: second,
              to: first,
              text: 'Ça va, et toi ?',
            );
          case 2:
            return MessageTurn(from: first, to: second, text: 'Ouais, ça va.');
          default:
            throw StateError(
              'Invalid message index for ça-va phase: $messageIndex',
            );
        }
    }
  }

  int _turnCountFor(BatchType type) {
    return type == BatchType.step1 ? 2 : 3;
  }
}

class _BatchSelection {
  const _BatchSelection({required this.type, required this.pairs});

  final BatchType type;
  final List<PairId> pairs;
}
