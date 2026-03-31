import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:salutcava/features/simulation/domain/protocol.dart';
import 'package:salutcava/features/simulation/domain/scheduler.dart';
import 'package:salutcava/features/simulation/domain/simulation_controller.dart';

void main() {
  group('SimulationController', () {
    test('completes all unordered pairs with expected turn count', () {
      final clock = _TestClock();
      final controller = SimulationController(
        config: const SimulationConfig(
          peopleCount: 4,
          maxConcurrent: 2,
          schedulerMode: SchedulerMode.deterministic,
        ),
        clock: clock.call,
      );

      _advanceUntilComplete(controller);

      final snapshot = controller.snapshot;
      expect(snapshot.completedPairs, snapshot.totalPairs);
      expect(snapshot.totalTurns, snapshot.totalPairs * 5);
      expect(snapshot.elapsed, isNotNull);
      expect(snapshot.elapsed!.inMilliseconds, greaterThan(0));
    });

    test('never schedules one person in two pairs of same batch', () {
      final controller = SimulationController(
        config: const SimulationConfig(
          peopleCount: 8,
          maxConcurrent: 4,
          schedulerMode: SchedulerMode.deterministic,
        ),
        random: Random(1),
      );

      while (!controller.snapshot.isComplete) {
        final messageStep = controller.advance();
        if (messageStep == null) {
          break;
        }

        expect(
          messageStep.turns,
          hasLength(messageStep.pairs.length),
          reason: 'Each tap should emit one message per active conversation.',
        );
        expect(
          messageStep.turns.length,
          lessThanOrEqualTo(4),
          reason: 'Messages per tap should never exceed max concurrent value.',
        );

        final busy = <int>{};
        for (final pair in messageStep.pairs) {
          expect(
            busy.add(pair.first),
            isTrue,
            reason: 'Person ${pair.first} scheduled twice in one batch',
          );
          expect(
            busy.add(pair.second),
            isTrue,
            reason: 'Person ${pair.second} scheduled twice in one batch',
          );
        }
      }
    });

    test('each pair emits two step1 and three step2 messages', () {
      final controller = SimulationController(
        config: const SimulationConfig(
          peopleCount: 6,
          maxConcurrent: 3,
          schedulerMode: SchedulerMode.deterministic,
        ),
        random: Random(7),
      );

      final step1Counts = <PairId, int>{};
      final step2Counts = <PairId, int>{};

      while (!controller.snapshot.isComplete) {
        final messageStep = controller.advance();
        if (messageStep == null) {
          break;
        }

        for (final turn in messageStep.turns) {
          final pair = turn.pair;

          if (turn.phase == BatchType.step1) {
            expect(
              step2Counts[pair] ?? 0,
              0,
              reason: '$pair reached step2 before completing step1.',
            );
            step1Counts[pair] = (step1Counts[pair] ?? 0) + 1;
          } else if (turn.phase == BatchType.step2) {
            expect(
              step1Counts[pair] ?? 0,
              2,
              reason: '$pair reached step2 before both step1 messages.',
            );
            step2Counts[pair] = (step2Counts[pair] ?? 0) + 1;
          } else {
            fail('Message turn phase should never be mixed.');
          }
        }
      }

      for (final pair in controller.snapshot.pairStates.keys) {
        expect(
          step1Counts[pair] ?? 0,
          2,
          reason: '$pair should receive exactly two step1 messages.',
        );
        expect(
          step2Counts[pair] ?? 0,
          3,
          reason: '$pair should receive exactly three step2 messages.',
        );
      }
    });

    test('first advance can emit multiple messages with concurrency', () {
      final controller = SimulationController(
        config: const SimulationConfig(
          peopleCount: 10,
          maxConcurrent: 5,
          schedulerMode: SchedulerMode.deterministic,
        ),
        random: Random(3),
      );

      final first = controller.advance();
      expect(first, isNotNull);
      expect(first!.pairs.length, 5);
      expect(first.turns.length, first.pairs.length);
    });

    test('keeps max concurrency in random mode while enough work exists', () {
      final controller = SimulationController(
        config: const SimulationConfig(
          peopleCount: 10,
          maxConcurrent: 3,
          schedulerMode: SchedulerMode.random,
        ),
        random: Random(42),
      );

      for (var i = 0; i < 20; i++) {
        final wave = controller.advance();
        expect(wave, isNotNull);
        expect(
          wave!.turns.length,
          3,
          reason: 'Concurrency should stay full while plenty of work remains.',
        );
      }
    });

    test('avoids early underfill in 6-person random mode across seeds', () {
      for (var seed = 0; seed < 50; seed++) {
        final controller = SimulationController(
          config: const SimulationConfig(
            peopleCount: 6,
            maxConcurrent: 3,
            schedulerMode: SchedulerMode.random,
          ),
          random: Random(seed),
        );

        for (var waveIndex = 0; waveIndex < 15; waveIndex++) {
          final wave = controller.advance();
          expect(wave, isNotNull, reason: 'Seed $seed ended too early.');
          expect(
            wave!.turns.length,
            3,
            reason:
                'Seed $seed dipped below max concurrency before endgame at wave $waveIndex.',
          );
        }
      }
    });

    test('uses all mathematically available slots each wave', () {
      for (var seed = 0; seed < 20; seed++) {
        final controller = SimulationController(
          config: const SimulationConfig(
            peopleCount: 6,
            maxConcurrent: 3,
            schedulerMode: SchedulerMode.random,
          ),
          random: Random(seed),
        );

        while (true) {
          final remainingPairs = controller.snapshot.pairStates.entries
              .where((entry) => entry.value != PairProgress.complete)
              .map((entry) => entry.key)
              .toList(growable: false);
          final theoretical = _maxNonOverlappingPairs(remainingPairs, 3);

          final wave = controller.advance();
          if (wave == null) {
            expect(theoretical, 0, reason: 'Simulation ended with work left.');
            break;
          }

          expect(
            wave.turns.length,
            theoretical,
            reason:
                'Seed $seed scheduled fewer conversations than theoretically possible.',
          );
        }
      }
    });
  });
}

void _advanceUntilComplete(SimulationController controller) {
  var guard = 0;
  while (!controller.snapshot.isComplete) {
    controller.advance();
    guard++;
    if (guard > 1000) {
      fail('Simulation did not complete within guard limit');
    }
  }
}

class _TestClock {
  DateTime _current = DateTime(2026, 1, 1, 8);

  DateTime call() {
    final now = _current;
    _current = _current.add(const Duration(milliseconds: 300));
    return now;
  }
}

int _maxNonOverlappingPairs(List<PairId> pairs, int maxConcurrent) {
  var best = 0;

  void search(int index, Set<int> busy, int count) {
    if (count > best) {
      best = count;
    }
    if (count >= maxConcurrent) {
      return;
    }

    for (var i = index; i < pairs.length; i++) {
      final pair = pairs[i];
      if (busy.contains(pair.first) || busy.contains(pair.second)) {
        continue;
      }

      busy.add(pair.first);
      busy.add(pair.second);
      search(i + 1, busy, count + 1);
      busy.remove(pair.first);
      busy.remove(pair.second);
    }
  }

  search(0, <int>{}, 0);
  return best;
}
