import 'translations.dart';

/// The translations for German (`de`).
class PicassoTranslationsDe extends PicassoTranslations {
  PicassoTranslationsDe([String locale = 'de']) : super(locale);

  @override
  String get filterName => 'Filter';

  @override
  String get backgroundImageName => 'Bild';

  @override
  String get stencilName => 'Schablone';

  @override
  String get stickerName => 'Sticker';

  @override
  String get textName => 'Text';

  @override
  String get doneButton => 'Fertig';

  @override
  String get continueButton => 'Weiter';

  @override
  String get none => 'Keiner';

  @override
  String get layersName => 'Ebenen';

  @override
  String get gifName => 'Gif';

  @override
  String get gifPlay => 'Animation abspielen';

  @override
  String get gifStop => 'Animation stoppen';

  @override
  String get layersCenter => 'Zentrieren';

  @override
  String get layersRemove => 'Entfernen';

  @override
  String get reset => 'Zurücksetzen';
}
