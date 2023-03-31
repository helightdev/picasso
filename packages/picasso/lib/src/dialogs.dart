import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'dart:ui' as ui;

/// Creates and shows a [PicassoEditor] using a [Dialog].
showPicassoEditorDialog({
  required BuildContext context,
  required SizedImage image,
  required void Function(RenderOutput output) callback,
  ThemeData? themeOverride,
  List<PicassoTool> tools = const [],
  CanvasSettings? settings,
  ToolDisplayWidgetFactory displayWidgetFactory =
      const ModernToolDisplayWidgetFactory(),
  EditorContainerFactory containerFactory =
      const ModernColumnEditorContainerFactory(),
  EditorBottomWidgetFactory? bottomWidgetFactory,
  Map<String,dynamic> bindings = const {},
  CanvasSaveData? saveData
}) async {
  var mq = MediaQuery.of(context);
  themeOverride ??= Theme.of(context);
  var combinedTools = [ImageTool(image, visible: true), ...tools];
  var editorKey = GlobalKey<PicassoEditorState>();
  showDialog(
      context: context,
      builder: (context) => Theme(
            data: themeOverride!,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: SizedBox(
                width: mq.size.width,
                height: mq.size.height,
                child: PicassoEditor(
                  key: editorKey,
                  settings: settings ?? CanvasSettings(width: 1080, height: 1080),
                  tools: combinedTools,
                  bindings: bindings,
                  saveData: saveData,
                  displayWidgetFactory: displayWidgetFactory,
                  containerFactory: containerFactory,
                  bottomWidgetFactory: bottomWidgetFactory ??
                      ElevatedButtonBottomWidgetFactory.$continue(onTap: () async {
                        var state = editorKey.currentState!;
                        var output = await state.canvas.getRenderOutput();
                        callback.call(output);
                        // ignore: use_build_context_synchronously
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }),
                ),
              ),
            ),
          ));
}


/// Creates and shows a [PicassoEditor] using a [Dialog].
showPicassoEditorDialogTools({
  required BuildContext context,
  required List<PicassoTool> tools,
  required void Function(RenderOutput output) callback,
  ThemeData? themeOverride,
  CanvasSettings? settings,
  ToolDisplayWidgetFactory displayWidgetFactory =
  const ModernToolDisplayWidgetFactory(),
  EditorContainerFactory containerFactory =
  const ModernColumnEditorContainerFactory(),
  EditorBottomWidgetFactory? bottomWidgetFactory,
  Map<String,dynamic> bindings = const {},
  CanvasSaveData? saveData
}) async {
  var mq = MediaQuery.of(context);
  themeOverride ??= Theme.of(context);
  var editorKey = GlobalKey<PicassoEditorState>();
  showDialog(
      context: context,
      builder: (context) => Theme(
        data: themeOverride!,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SizedBox(
            width: mq.size.width,
            height: mq.size.height,
            child: PicassoEditor(
              key: editorKey,
              settings: settings ?? CanvasSettings(width: 1080, height: 1080),
              tools: tools,
              bindings: bindings,
              saveData: saveData,
              displayWidgetFactory: displayWidgetFactory,
              containerFactory: containerFactory,
              bottomWidgetFactory: bottomWidgetFactory ??
                  ElevatedButtonBottomWidgetFactory.$continue(onTap: () async {
                    var state = editorKey.currentState!;
                    var output = await state.canvas.getRenderOutput();
                    callback.call(output);
                    // ignore: use_build_context_synchronously
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }),
            ),
          ),
        ),
      ));
}

mixin SingleSliderValue {
  double get value;

  set value(double value);

  void reset() {}

  void scheduleRebuild(PicassoCanvasState state);
}

void showSingleSliderDialog(
    BuildContext context, SingleSliderValue layer, PicassoEditorState state,
    {bool resettable = false}) {
  showModalBottomSheet(
      context: context,
      builder: (context) => _SingleSliderDialog(
            state: state,
            layer: layer,
            resettable: resettable,
          ));
}

// ignore: must_be_immutable
class _SingleSliderDialog extends StatefulWidget {
  final SingleSliderValue layer;
  final PicassoEditorState state;
  final bool resettable;

  const _SingleSliderDialog(
      {required this.state, required this.layer, required this.resettable});

  @override
  State<_SingleSliderDialog> createState() => _SingleSliderDialogState();
}

class _SingleSliderDialogState extends State<_SingleSliderDialog> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: _SingleSliderValueSlider(
                layer: widget.layer,
                editorState: widget.state,
              ),
            ),
          ),
          if (widget.resettable)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                  onPressed: () {
                    widget.layer.reset();
                    widget.layer.scheduleRebuild(widget.state.canvas);
                    setState(() {});
                  },
                  icon: const Icon(Icons.undo)),
            )
        ],
      ),
    );
  }
}

class _SingleSliderValueSlider extends StatefulWidget {
  final PicassoEditorState editorState;
  final SingleSliderValue layer;

  const _SingleSliderValueSlider(
      {Key? key, required this.layer, required this.editorState})
      : super(key: key);

  @override
  State<_SingleSliderValueSlider> createState() =>
      _SingleSliderValueSliderState();
}

class _SingleSliderValueSliderState extends State<_SingleSliderValueSlider> {
  @override
  Widget build(BuildContext context) {
    return Slider(
        value: widget.layer.value,
        min: 0.0,
        max: 1.0,
        onChanged: (val) {
          widget.layer.value = val;
          widget.layer.scheduleRebuild(widget.editorState.canvas);
          setState(() {});
        });
  }
}
