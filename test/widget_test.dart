import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salutcava/features/simulation/presentation/simulation_page.dart';
import 'package:salutcava/main.dart';

void main() {
  testWidgets('tapping arena advances total turns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SalutCaVaApp());

    expect(find.text('Turns: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('simulation-arena')));
    await tester.pump();

    expect(find.text('Turns: 1'), findsOneWidget);
  });

  testWidgets('small simulation reaches completion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SimulationPage(initialPeopleCount: 2, initialMaxConcurrent: 1),
      ),
    );

    expect(find.byKey(const Key('completion-banner')), findsNothing);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('simulation-arena')));
      await tester.pump();
    }

    expect(find.byKey(const Key('completion-banner')), findsOneWidget);
    expect(find.textContaining('Everyone greeted everyone'), findsOneWidget);
  });
}
