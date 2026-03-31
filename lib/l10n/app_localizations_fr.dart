// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Salut, ça va ?';

  @override
  String get configuration => 'Configuration';

  @override
  String peopleInCircle(int count) {
    return 'Personnes dans le cercle : $count (2-20)';
  }

  @override
  String concurrentConversations(int count) {
    return 'Conversations simultanées : $count (1-5)';
  }

  @override
  String get schedulingMode => 'Mode d\'ordonnancement';

  @override
  String get schedulerModeDeterministic => 'Déterministe';

  @override
  String get schedulerModeRandom => 'Aléatoire';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get arenaCompletedHint =>
      'Conversation terminée. Réinitialisez pour recommencer.';

  @override
  String get arenaTapHint =>
      'Touchez cette zone pour avancer d\'un tour de messages.';

  @override
  String turnsLabel(int turns) {
    return 'Tours : $turns';
  }

  @override
  String pairsLabel(int completed, int total) {
    return 'Paires : $completed/$total';
  }

  @override
  String elapsedLabel(String elapsed) {
    return 'Temps écoulé : $elapsed';
  }

  @override
  String get statusCompleteLabel => 'Statut : terminé';

  @override
  String nextLabel(String exchange) {
    return 'Prochain échange : $exchange';
  }

  @override
  String get exchangeSalut => 'Salut';

  @override
  String get exchangeCaVa => 'Ça va';

  @override
  String get noMessageYet => 'Aucun message. Touchez la zone pour commencer.';

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
    return 'Tout le monde s\'est salué en $turns tours en $elapsed.';
  }
}
