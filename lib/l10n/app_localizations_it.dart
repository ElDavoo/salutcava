// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Salut, ça va ?';

  @override
  String get configuration => 'Configurazione';

  @override
  String peopleInCircle(int count) {
    return 'Persone nel cerchio: $count (2-20)';
  }

  @override
  String concurrentConversations(int count) {
    return 'Conversazioni simultanee: $count (1-5)';
  }

  @override
  String get schedulingMode => 'Modalità di pianificazione';

  @override
  String get schedulerModeDeterministic => 'Deterministico';

  @override
  String get schedulerModeRandom => 'Casuale';

  @override
  String get reset => 'Reimposta';

  @override
  String get arenaCompletedHint =>
      'Conversazione completata. Reimposta per ricominciare.';

  @override
  String get arenaTapHint =>
      'Tocca quest\'area per avanzare di un turno di messaggi.';

  @override
  String turnsLabel(int turns) {
    return 'Turni: $turns';
  }

  @override
  String pairsLabel(int completed, int total) {
    return 'Coppie: $completed/$total';
  }

  @override
  String elapsedLabel(String elapsed) {
    return 'Tempo trascorso: $elapsed';
  }

  @override
  String get statusCompleteLabel => 'Stato: completato';

  @override
  String nextLabel(String exchange) {
    return 'Prossimo scambio: $exchange';
  }

  @override
  String get exchangeSalut => 'Salut';

  @override
  String get exchangeCaVa => 'Ça va';

  @override
  String get noMessageYet => 'Nessun messaggio. Tocca l\'area per iniziare.';

  @override
  String lastMessageHeader(String exchange, int pairCount) {
    String _temp0 = intl.Intl.pluralLogic(
      pairCount,
      locale: localeName,
      other: '# conversazioni',
      one: '# conversazione',
    );
    return '$exchange ($_temp0)';
  }

  @override
  String completionBanner(int turns, String elapsed) {
    return 'Tutti si sono salutati in $turns turni in $elapsed.';
  }
}
