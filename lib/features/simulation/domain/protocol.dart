import 'dart:collection';
import 'dart:math';

enum BatchType { step1, step2 }

extension BatchTypeLabel on BatchType {
  String get label {
    switch (this) {
      case BatchType.step1:
        return 'Salut';
      case BatchType.step2:
        return 'Ça va';
    }
  }
}

enum PairProgress { notStarted, step1Done, complete }

class PairId {
  PairId(int a, int b) : assert(a != b), first = min(a, b), second = max(a, b);

  final int first;
  final int second;

  bool contains(int personId) => first == personId || second == personId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PairId && first == other.first && second == other.second;
  }

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => 'P${first + 1}<->P${second + 1}';
}

class MessageTurn {
  const MessageTurn({required this.from, required this.to, required this.text});

  final int from;
  final int to;
  final String text;

  PairId get pair => PairId(from, to);
}

class BatchExecution {
  BatchExecution({
    required this.type,
    required List<PairId> pairs,
    required List<MessageTurn> turns,
  }) : pairs = List<PairId>.unmodifiable(pairs),
       turns = List<MessageTurn>.unmodifiable(turns);

  final BatchType type;
  final List<PairId> pairs;
  final List<MessageTurn> turns;
}

class SimulationSnapshot {
  SimulationSnapshot({
    required this.peopleCount,
    required this.maxConcurrent,
    required this.nextBatchType,
    required Map<PairId, PairProgress> pairStates,
    required this.totalTurns,
    required this.history,
    required this.startedAt,
    required this.finishedAt,
    required this.elapsed,
    this.lastBatch,
  }) : pairStates = UnmodifiableMapView<PairId, PairProgress>(
         Map<PairId, PairProgress>.from(pairStates),
       );

  final int peopleCount;
  final int maxConcurrent;
  final BatchType nextBatchType;
  final Map<PairId, PairProgress> pairStates;
  final int totalTurns;
  final List<BatchExecution> history;
  final BatchExecution? lastBatch;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final Duration? elapsed;

  int get totalPairs => peopleCount * (peopleCount - 1) ~/ 2;

  int get completedPairs {
    return pairStates.values
        .where((state) => state == PairProgress.complete)
        .length;
  }

  bool get isComplete => finishedAt != null;
}
