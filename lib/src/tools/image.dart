import 'dart:math';

import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'dart:ui' as ui;

class SizedImage {
  final ImageProvider image;
  final Size dimensions;

  const SizedImage(this.image, this.dimensions);
}

class BackgroundImageTool extends PicassoTool with BakeTarget {
  final String? name;
  final IconData icon;
  final ui.Image image;

  const BackgroundImageTool(this.image,
      {this.name, this.icon = Icons.image, super.visible = true})
      : super();

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.backgroundImageName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    var layer = BackgroundImageLayer(image);
    var canvasRect =
        Rect.fromPoints(Offset.zero, state.canvas.canvasSizeOffset);
    var transform = scaleToRatioCover(canvasRect, null, layer, 1.0);
    transform = makeCentered(canvasRect, transform, layer);
    state.canvas.addLayer(layer, transform);
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    showModalBottomSheet(
        context: context,
        builder: (context) => _BackgroundImageDialog(state: state, tool: this));
  }

  @override
  void onBake(PicassoEditorState state, ui.Image image) {
    var layer = state.canvas.findLayerOfType<BackgroundImageLayer>();
    layer.source = image;
    layer.output = image;
    layer.libSourceImage = null;
    state.canvas.transforms[state.canvas.indexOf(layer)] =
        scaleToRatioContain(state.canvas.rect, null, layer, 1.0);
    layer.render(state.canvas);
  }
}

class BackgroundImageLayer extends PicassoLayer with RawImageTarget {
  @override
  ui.Image source;
  @override
  late ui.Image output;

  bool flipped = false;

  BackgroundImageLayer(this.source, {super.rotatable = false})
      : super(
            promoting: false,
            deletable: false,
            snapping: false,
            forceRotatable: true,
            cover: true) {
    output = source;
  }

  @override
  Size? calculateSize(Size canvas, TransformData data) =>
      Size(source.width * data.scale, source.height * data.scale);

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    Widget widget = RawImage(
      image: output,
      width: source.width * data.scale,
      height: source.height * data.scale,
      fit: BoxFit.fill,
    );

    if (flipped) {
      widget = Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(pi),
          child: widget);
    }
    return widget;
  }
}

class _BackgroundImageDialog extends StatefulWidget {
  final BackgroundImageTool tool;
  final PicassoEditorState state;

  const _BackgroundImageDialog({required this.state, required this.tool});

  @override
  State<_BackgroundImageDialog> createState() => _BackgroundImageDialogState();
}

class _BackgroundImageDialogState extends State<_BackgroundImageDialog> {
  @override
  Widget build(BuildContext context) {
    var canvas = widget.state.canvas;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                var layer = canvas.findLayerOfType<BackgroundImageLayer>();
                layer.flipped = !layer.flipped;
                layer.setDirty(canvas);
              },
              icon: const Icon(Icons.flip)),
          IconButton(
              onPressed: () {
                var layer = canvas.findLayerOfType<BackgroundImageLayer>();
                var transform = canvas.transforms[canvas.indexOf(layer)];
                canvas.updateTransform(
                    layer,
                    transform.copyWith(
                        rotation: transform.rotation + (0.5 * pi)));
                canvas.scheduleRebuild();
              },
              icon: const Icon(Icons.rotate_right)),
          IconButton(
              onPressed: () {
                var layer = canvas.findLayerOfType<BackgroundImageLayer>();
                var transform = canvas.transforms[canvas.indexOf(layer)];
                canvas.updateTransform(
                    layer,
                    transform.copyWith(
                        rotation: transform.rotation - (0.5 * pi)));
                canvas.scheduleRebuild();
              },
              icon: const Icon(Icons.rotate_left)),
          IconButton(
              onPressed: () {
                widget.state.bake(context);
              },
              icon: const Icon(Icons.iron))
        ],
      ),
    );
  }
}
