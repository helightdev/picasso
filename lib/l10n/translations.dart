import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'translations_de.dart';
import 'translations_en.dart';

/// Callers can lookup localized strings with an instance of PicassoTranslations
/// returned by `PicassoTranslations.of(context)`.
///
/// Applications need to include `PicassoTranslations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/translations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PicassoTranslations.localizationsDelegates,
///   supportedLocales: PicassoTranslations.supportedLocales,
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
/// be consistent with the languages listed in the PicassoTranslations.supportedLocales
/// property.
abstract class PicassoTranslations {
  PicassoTranslations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PicassoTranslations of(BuildContext context) {
    return Localizations.of<PicassoTranslations>(context, PicassoTranslations)!;
  }

  static const LocalizationsDelegate<PicassoTranslations> delegate =
      _PicassoTranslationsDelegate();

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
    Locale('de'),
    Locale('en')
  ];

  ///
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterName;

  ///
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get backgroundImageName;

  ///
  ///
  /// In en, this message translates to:
  /// **'Stencil'**
  String get stencilName;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get stickerName;

  ///
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textName;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;
}

class _PicassoTranslationsDelegate
    extends LocalizationsDelegate<PicassoTranslations> {
  const _PicassoTranslationsDelegate();

  @override
  Future<PicassoTranslations> load(Locale locale) {
    return SynchronousFuture<PicassoTranslations>(
        lookupPicassoTranslations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_PicassoTranslationsDelegate old) => false;
}

PicassoTranslations lookupPicassoTranslations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return PicassoTranslationsDe();
    case 'en':
      return PicassoTranslationsEn();
  }

  throw FlutterError(
      'PicassoTranslations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
