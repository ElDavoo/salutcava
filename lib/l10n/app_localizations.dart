import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Salut, ça va ?'**
  String get appTitle;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @peopleInCircle.
  ///
  /// In en, this message translates to:
  /// **'People in circle: {count} (2-20)'**
  String peopleInCircle(int count);

  /// No description provided for @concurrentConversations.
  ///
  /// In en, this message translates to:
  /// **'Concurrent conversations: {count} (1-5)'**
  String concurrentConversations(int count);

  /// No description provided for @schedulingMode.
  ///
  /// In en, this message translates to:
  /// **'Scheduling mode'**
  String get schedulingMode;

  /// No description provided for @schedulerModeDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Deterministic'**
  String get schedulerModeDeterministic;

  /// No description provided for @schedulerModeRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get schedulerModeRandom;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @arenaCompletedHint.
  ///
  /// In en, this message translates to:
  /// **'Conversation complete. Reset to run again.'**
  String get arenaCompletedHint;

  /// No description provided for @arenaTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere in this area to advance one message wave.'**
  String get arenaTapHint;

  /// No description provided for @turnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Turns: {turns}'**
  String turnsLabel(int turns);

  /// No description provided for @pairsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairs: {completed}/{total}'**
  String pairsLabel(int completed, int total);

  /// No description provided for @elapsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Elapsed: {elapsed}'**
  String elapsedLabel(String elapsed);

  /// No description provided for @statusCompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: Complete'**
  String get statusCompleteLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next exchange: {exchange}'**
  String nextLabel(String exchange);

  /// No description provided for @exchangeSalut.
  ///
  /// In en, this message translates to:
  /// **'Salut'**
  String get exchangeSalut;

  /// No description provided for @exchangeCaVa.
  ///
  /// In en, this message translates to:
  /// **'Ça va'**
  String get exchangeCaVa;

  /// No description provided for @noMessageYet.
  ///
  /// In en, this message translates to:
  /// **'No message yet. Tap the arena to start.'**
  String get noMessageYet;

  /// No description provided for @lastMessageHeader.
  ///
  /// In en, this message translates to:
  /// **'{exchange} ({pairCount, plural, =1{# conversation} other{# conversations}})'**
  String lastMessageHeader(String exchange, int pairCount);

  /// No description provided for @completionBanner.
  ///
  /// In en, this message translates to:
  /// **'Everyone greeted everyone in {turns} turns over {elapsed}.'**
  String completionBanner(int turns, String elapsed);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
