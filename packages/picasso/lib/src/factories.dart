import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

export 'factories/modern.dart';
export 'factories/material.dart';

/// Abstract factory for creating [Widget]s from [PicassoToolDisplay]s.
abstract class ToolDisplayWidgetFactory {
  const ToolDisplayWidgetFactory();

  Size getSize(BuildContext context, bool dense);

  Widget get(BuildContext context, PicassoToolDisplay display,
      void Function() callback, bool dense);
}

/// Abstract factory for creating the container [Widget] for the [PicassoEditor].
abstract class EditorContainerFactory {
  const EditorContainerFactory();

  Widget get(BuildContext context, PicassoEditorState state,
      BoxConstraints constraints);
}

/// Abstract factory for creating the bottom widget of a [PicassoEditor].
abstract class EditorBottomWidgetFactory {
  const EditorBottomWidgetFactory();

  factory EditorBottomWidgetFactory.fromPreferred(PreferredSizeWidget widget) =>
      PreferredSizeEditorBottomWidget(widget);

  Size getSize(BuildContext context, PicassoEditorState state);

  Widget get(BuildContext context, PicassoEditorState state);
}

/// Abstract factory for displaying dialogs inside [PicassoEditor] views.
abstract class EditorDialogFactory {
  const EditorDialogFactory();

  Future<String> promptText(BuildContext context, {String? prefix, String? initialValue, TextStyle? style});

  void showDialog(BuildContext context, WidgetBuilder builder);

}

class PreferredSizeEditorBottomWidget extends EditorBottomWidgetFactory {
  final PreferredSizeWidget widget;
  const PreferredSizeEditorBottomWidget(this.widget);

  @override
  Widget get(BuildContext context, PicassoEditorState state) {
    return widget;
  }

  @override
  Size getSize(BuildContext context, PicassoEditorState state) {
    return widget.preferredSize;
  }
}
