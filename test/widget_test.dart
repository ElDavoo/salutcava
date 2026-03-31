import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salutcava/features/simulation/presentation/simulation_page.dart';
import 'package:salutcava/l10n/app_localizations.dart';
import 'package:salutcava/main.dart';

void main() {
  testWidgets('tapping arena advances total turns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SalutCaVaApp());
    await tester.pumpAndSettle();

    final turnCountFinder = find.byKey(const Key('turn-count'));
    expect(turnCountFinder, findsOneWidget);
    final beforeCount = _readCountFromText(
      (tester.widget<Text>(turnCountFinder)).data!,
    );
    expect(beforeCount, 0);

    await tester.tap(find.byKey(const Key('simulation-arena')));
    await tester.pump();

    final afterCount = _readCountFromText(
      (tester.widget<Text>(turnCountFinder)).data!,
    );
    expect(afterCount, greaterThan(0));
  });

  testWidgets('small simulation reaches completion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SimulationPage(initialPeopleCount: 2, initialMaxConcurrent: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('completion-banner')), findsNothing);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('simulation-arena')));
      await tester.pump();
    }

    expect(find.byKey(const Key('completion-banner')), findsOneWidget);
  });

  testWidgets('italian localization is rendered', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SimulationPage(initialPeopleCount: 2, initialMaxConcurrent: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reimposta'), findsOneWidget);
  });
}

int _readCountFromText(String text) {
  final match = RegExp(r'(\d+)').firstMatch(text);
  if (match == null) {
    throw StateError('No numeric value found in "$text"');
  }
  return int.parse(match.group(1)!);
}
