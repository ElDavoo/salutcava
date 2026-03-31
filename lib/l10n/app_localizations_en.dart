// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Salut, ça va ?';

  @override
  String get configuration => 'Configuration';

  @override
  String peopleInCircle(int count) {
    return 'People in circle: $count (2-20)';
  }

  @override
  String concurrentConversations(int count) {
    return 'Concurrent conversations: $count (1-5)';
  }

  @override
  String get schedulingMode => 'Scheduling mode';

  @override
  String get schedulerModeDeterministic => 'Deterministic';

  @override
  String get schedulerModeRandom => 'Random';

  @override
  String get reset => 'Reset';

  @override
  String get arenaCompletedHint => 'Conversation complete. Reset to run again.';

  @override
  String get arenaTapHint =>
      'Tap anywhere in this area to advance one message wave.';

  @override
  String turnsLabel(int turns) {
    return 'Turns: $turns';
  }

  @override
  String pairsLabel(int completed, int total) {
    return 'Pairs: $completed/$total';
  }

  @override
  String elapsedLabel(String elapsed) {
    return 'Elapsed: $elapsed';
  }

  @override
  String get statusCompleteLabel => 'Status: Complete';

  @override
  String nextLabel(String exchange) {
    return 'Next exchange: $exchange';
  }

  @override
  String get exchangeSalut => 'Salut';

  @override
  String get exchangeCaVa => 'Ça va';

  @override
  String get noMessageYet => 'No message yet. Tap the arena to start.';

  @override
  String lastMessageHeader(String exchange, int pairCount) {
    String _temp0 = intl.Intl.pluralLogic(
      pairCount,
      locale: localeName,
      other: '# conversations',
      one: '# conversation',
    );
    return '$exchange ($_temp0)';
  }

  @override
  String completionBanner(int turns, String elapsed) {
    return 'Everyone greeted everyone in $turns turns over $elapsed.';
  }
}
