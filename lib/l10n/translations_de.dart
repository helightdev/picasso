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
}
