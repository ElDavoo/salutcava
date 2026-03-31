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
       _scheduler =
           scheduler ?? buildScheduler(config.schedulerMode, random: random) {
    _initialize();
  }

  SimulationConfig _config;
  final Clock _clock;
  PairScheduler _scheduler;

  late Map<PairId, PairProgress> _pairStates;
  final List<BatchExecution> _history = <BatchExecution>[];
  List<_QueuedTurn> _pendingTurns = <_QueuedTurn>[];
  BatchType? _activeBatchType;
  List<PairId> _activeBatchPairs = const <PairId>[];
  BatchType _nextBatchType = BatchType.step1;
  int _totalTurns = 0;
  DateTime? _startedAt;
  DateTime? _finishedAt;

  late SimulationSnapshot _snapshot;

  SimulationSnapshot get snapshot => _snapshot;

  void updateConfig(SimulationConfig newConfig, {Random? random}) {
    _config = newConfig;
    _scheduler = buildScheduler(newConfig.schedulerMode, random: random);
    _initialize();
  }

  void restart({Random? random}) {
    _scheduler = buildScheduler(_config.schedulerMode, random: random);
    _initialize();
  }

  BatchExecution? advance() {
    if (_finishedAt != null) {
      return null;
    }

    _startedAt ??= _clock();

    if (_pendingTurns.isEmpty) {
      var batchType = _nextBatchType;
      var eligible = _eligiblePairs(batchType);

      if (eligible.isEmpty) {
        batchType = _toggleBatchType(batchType);
        eligible = _eligiblePairs(batchType);
      }

      if (eligible.isEmpty) {
        _finishedAt = _clock();
        _snapshot = _buildSnapshot();
        return null;
      }

      final selected = _scheduler.selectPairs(
        candidates: eligible,
        maxConcurrent: _config.maxConcurrent,
      );
      final pairsToRun = selected.isEmpty ? <PairId>[eligible.first] : selected;

      _activeBatchType = batchType;
      _activeBatchPairs = List<PairId>.unmodifiable(pairsToRun);
      _pendingTurns = _buildPendingTurns(pairsToRun, batchType);
      _nextBatchType = _toggleBatchType(batchType);
    }

    final queuedTurn = _pendingTurns.removeAt(0);
    final activeBatchType = _activeBatchType!;

    if (queuedTurn.completesPair) {
      _pairStates[queuedTurn.pair] = activeBatchType == BatchType.step1
          ? PairProgress.step1Done
          : PairProgress.complete;
    }

    _totalTurns++;
    final execution = BatchExecution(
      type: activeBatchType,
      pairs: _activeBatchPairs,
      turns: <MessageTurn>[queuedTurn.turn],
    );
    _history.add(execution);

    if (_pendingTurns.isEmpty) {
      _activeBatchType = null;
      _activeBatchPairs = const <PairId>[];

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
    _pendingTurns = <_QueuedTurn>[];
    _activeBatchType = null;
    _activeBatchPairs = const <PairId>[];
    _nextBatchType = BatchType.step1;
    _totalTurns = 0;
    _startedAt = null;
    _finishedAt = null;
    _snapshot = _buildSnapshot();
  }

  SimulationSnapshot _buildSnapshot({BatchExecution? lastBatch}) {
    final displayBatchType = _activeBatchType ?? _nextBatchType;
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

  List<PairId> _eligiblePairs(BatchType batchType) {
    switch (batchType) {
      case BatchType.step1:
        return _pairStates.entries
            .where((entry) => entry.value == PairProgress.notStarted)
            .map((entry) => entry.key)
            .toList();
      case BatchType.step2:
        return _pairStates.entries
            .where((entry) => entry.value == PairProgress.step1Done)
            .map((entry) => entry.key)
            .toList();
    }
  }

  static BatchType _toggleBatchType(BatchType batchType) {
    return batchType == BatchType.step1 ? BatchType.step2 : BatchType.step1;
  }

  List<_QueuedTurn> _buildPendingTurns(
    List<PairId> pairs,
    BatchType batchType,
  ) {
    final perPairTurns = <PairId, List<MessageTurn>>{
      for (final pair in pairs) pair: _turnsForPair(pair, batchType),
    };

    final queue = <_QueuedTurn>[];
    final turnsPerPair = perPairTurns[pairs.first]!.length;
    for (var turnIndex = 0; turnIndex < turnsPerPair; turnIndex++) {
      for (final pair in pairs) {
        final pairTurns = perPairTurns[pair]!;
        queue.add(
          _QueuedTurn(
            pair: pair,
            turn: pairTurns[turnIndex],
            completesPair: turnIndex == pairTurns.length - 1,
          ),
        );
      }
    }

    return queue;
  }

  List<MessageTurn> _turnsForPair(PairId pair, BatchType batchType) {
    final first = pair.first;
    final second = pair.second;

    switch (batchType) {
      case BatchType.step1:
        return <MessageTurn>[
          MessageTurn(from: first, to: second, text: 'Salut'),
          MessageTurn(from: second, to: first, text: 'Salut'),
        ];
      case BatchType.step2:
        return <MessageTurn>[
          MessageTurn(from: first, to: second, text: 'Ca va?'),
          MessageTurn(from: second, to: first, text: 'Ca va, et toi?'),
          MessageTurn(from: first, to: second, text: 'Ouais, ca va.'),
        ];
    }
  }
}

class _QueuedTurn {
  const _QueuedTurn({
    required this.pair,
    required this.turn,
    required this.completesPair,
  });

  final PairId pair;
  final MessageTurn turn;
  final bool completesPair;
}
