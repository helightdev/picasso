import 'translations.dart';

/// The translations for English (`en`).
class PicassoTranslationsEn extends PicassoTranslations {
  PicassoTranslationsEn([String locale = 'en']) : super(locale);

  @override
  String get filterName => 'Filter';

  @override
  String get backgroundImageName => 'Image';

  @override
  String get stencilName => 'Stencil';

  @override
  String get stickerName => 'Sticker';

  @override
  String get textName => 'Text';

  @override
  String get doneButton => 'Done';

  @override
  String get continueButton => 'Continue';

  @override
  String get none => 'None';
}
