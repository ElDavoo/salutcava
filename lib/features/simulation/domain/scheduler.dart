import 'dart:math';

import 'protocol.dart';

enum SchedulerMode { deterministic, random }

extension SchedulerModeLabel on SchedulerMode {
  String get label {
    switch (this) {
      case SchedulerMode.deterministic:
        return 'Deterministic';
      case SchedulerMode.random:
        return 'Random';
    }
  }
}

abstract class PairScheduler {
  List<PairId> selectPairs({
    required List<PairId> candidates,
    required int maxConcurrent,
  });
}

PairScheduler buildScheduler(SchedulerMode mode, {Random? random}) {
  switch (mode) {
    case SchedulerMode.deterministic:
      return const DeterministicPairScheduler();
    case SchedulerMode.random:
      return RandomPairScheduler(random ?? Random());
  }
}

class DeterministicPairScheduler implements PairScheduler {
  const DeterministicPairScheduler();

  @override
  List<PairId> selectPairs({
    required List<PairId> candidates,
    required int maxConcurrent,
  }) {
    final sorted = List<PairId>.from(candidates)
      ..sort((left, right) {
        final firstOrder = left.first.compareTo(right.first);
        if (firstOrder != 0) {
          return firstOrder;
        }
        return left.second.compareTo(right.second);
      });
    return _selectNonOverlapping(sorted, maxConcurrent);
  }
}

class RandomPairScheduler implements PairScheduler {
  RandomPairScheduler(this._random);

  final Random _random;

  @override
  List<PairId> selectPairs({
    required List<PairId> candidates,
    required int maxConcurrent,
  }) {
    final shuffled = List<PairId>.from(candidates)..shuffle(_random);
    return _selectNonOverlapping(shuffled, maxConcurrent);
  }
}

List<PairId> _selectNonOverlapping(List<PairId> ordered, int maxConcurrent) {
  final selected = <PairId>[];
  final busyPeople = <int>{};

  for (final pair in ordered) {
    if (selected.length >= maxConcurrent) {
      break;
    }
    if (busyPeople.contains(pair.first) || busyPeople.contains(pair.second)) {
      continue;
    }
    selected.add(pair);
    busyPeople.add(pair.first);
    busyPeople.add(pair.second);
  }

  return selected;
}
