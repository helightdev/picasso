import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'package:image/image.dart' as img;

class RawBrightnessTool extends PicassoTool {
  final String? name;
  final IconData icon;

  const RawBrightnessTool({
    this.name,
    this.icon = Icons.lightbulb,
  });

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) {
    return PicassoToolDisplay(name ?? "Brightness", icon);
  }

  @override
  void initialise(BuildContext context, PicassoEditorState state) {}

  @override
  void lateInitialise(BuildContext context, PicassoEditorState state) {
    var target = state.canvas.findLayerOfType<RawImageTarget>();
    target.addTransformer(BrightnessTransformer());
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    var layer = state.canvas.findLayerOfType<RawImageTarget>();
    var transformer =
        layer.transformers.whereType<BrightnessTransformer>().first;
    showSingleSliderDialog(context, transformer, state, resettable: true);
  }
}

class BrightnessTransformer extends RawImageTransformer with SingleSliderValue {
  BrightnessTransformer();

  @override
  double value = 1;

  @override
  void reset() {
    value = 1;
  }

  @override
  void scheduleRebuild(PicassoCanvasState state) {
    state.findLayerOfType<RawImageTarget>().render(state);
  }

  @override
  Future<img.Image> apply(img.Image image, PicassoCanvasState state) async {
    final cmd = img.Command()
      ..image(image)
      ..adjustColor(brightness: value);
    await cmd.executeThread();
    return cmd.outputImage!;
  }
}
