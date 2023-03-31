import 'dart:math';

import 'package:duffer/duffer.dart';
import 'package:duffer/src/bytebuf_base.dart';
import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class RawImageTool extends PicassoTool with BakeTarget {
  final String? name;
  final IconData icon;
  final ui.Image image;

  const RawImageTool(this.image,
      {this.name, this.icon = Icons.image, super.visible = true})
      : super();

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.backgroundImageName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    state.canvas.getOrCreateLayerOfType<RawImageLayer>(() {
      var layer = RawImageLayer(image);
      var canvasRect =
      Rect.fromPoints(Offset.zero, state.canvas.canvasSizeOffset);
      var transform = scaleToRatioCover(canvasRect, null, layer, 1.0);
      transform = makeCentered(canvasRect, transform, layer);
      return [layer, transform];
    });
  }

  @override
  void lateInitialise(BuildContext context, PicassoEditorState state) {
    state.canvas.findLayersOfType<RawImageLayer>().forEach((element) {
      element.associatedTool = this;
    });
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    state.widget.dialogFactory.showDialog(
        context, (context) => _RawImageDialog(state: state, tool: this));
  }

  @override
  void onBake(PicassoEditorState state, ui.Image image) {
    var layer = state.canvas.findLayerOfType<RawImageLayer>();
    layer.source = image;
    layer.output = image;
    layer.libSourceImage = null;
    state.canvas.transforms[state.canvas.indexOf(layer)] =
        scaleToRatioContain(state.canvas.rect, null, layer, 1.0);
    layer.render(state.canvas);
  }

  @override
  Iterable<PopupMenuEntry<VoidCallback>> getLayerOptions(
      BuildContext context, PicassoEditorState state, PicassoLayer layer) sync* {
    yield PopupMenuItem(child: Text(state.translations.reset), value: () {
      var canvasRect = Rect.fromPoints(Offset.zero, state.canvas.canvasSizeOffset);
      var transform = scaleToRatioCover(canvasRect, null, layer, 1.0);
      transform = makeCentered(canvasRect, transform, layer);
      state.canvas.updateTransform(layer, transform);
      layer.setDirty(state.canvas);
    });
  }
}

class RawImageLayer extends PicassoLayer with RawImageTarget {
  @override
  ui.Image source;
  @override
  late ui.Image output;

  bool flipped = false;

  RawImageLayer(this.source) : super(
      flags: LayerFlags.presetBackground | LayerFlags.logicRotatable,
      name: "Image") {
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

class RawImageLayerSerializer extends PicassoLayerSerializer {
  RawImageLayerSerializer() : super("picasso:raw_image");

  @override
  bool check(PicassoLayer layer) {
    return layer is RawImageLayer;
  }

  @override
  Future<PicassoLayer> deserialize(ByteBuf buf, PicassoCanvasState state,
      PicassoEditorState? editorState) async {
    var flipped = buf.readBool();
    var byteCount = buf.readInt64();
    var bytes = buf.readBytes(byteCount);
    var img = await loadImageFromProvider(MemoryImage(bytes));
    var layer = RawImageLayer(img);
    layer.flipped = flipped;
    return layer;
  }

  @override
  Future serialize(
      PicassoLayer layer, ByteBuf buf, PicassoCanvasState state) async {
    var imageLayer = layer as RawImageLayer;
    var data =
    await imageLayer.source.toByteData(format: ui.ImageByteFormat.png);
    var bytes = data!.buffer.asUint8List();
    buf.writeBool(imageLayer.flipped);
    buf.writeInt64(bytes.length);
    buf.writeBytes(bytes);
  }
}

class _RawImageDialog extends StatefulWidget {
  final RawImageTool tool;
  final PicassoEditorState state;

  const _RawImageDialog({required this.state, required this.tool});

  @override
  State<_RawImageDialog> createState() => _RawImageDialogState();
}

class _RawImageDialogState extends State<_RawImageDialog> {
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
                var layer = canvas.findLayerOfType<RawImageLayer>();
                layer.flipped = !layer.flipped;
                layer.setDirty(canvas);
              },
              icon: const Icon(Icons.flip)),
          IconButton(
              onPressed: () {
                var layer = canvas.findLayerOfType<RawImageLayer>();
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
                var layer = canvas.findLayerOfType<RawImageLayer>();
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
