import 'dart:math';

import 'package:duffer/duffer.dart';
import 'package:duffer/src/bytebuf_base.dart';
import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

class ImageTool extends PicassoTool {
  final String? name;
  final IconData icon;
  final SizedImage image;

  const ImageTool(this.image,
      {this.name, this.icon = Icons.image, super.visible = true})
      : super();

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.backgroundImageName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    state.canvas.getOrCreateLayerOfType<ImageLayer>(() {
      var layer = ImageLayer(image);
      var canvasRect =
          Rect.fromPoints(Offset.zero, state.canvas.canvasSizeOffset);
      var transform = scaleToRatioCover(canvasRect, null, layer, 1.0);
      transform = makeCentered(canvasRect, transform, layer);
      return [layer, transform];
    });
  }

  @override
  void lateInitialise(BuildContext context, PicassoEditorState state) {
    state.canvas.findLayersOfType<ImageLayer>().forEach((element) {
      element.associatedTool = this;
    });
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

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    state.widget.dialogFactory.showDialog(
        context, (context) => _ImageDialog(state: state, tool: this));
  }
}

class ImageLayer extends PicassoLayer{
  
  SizedImage image;
  bool flipped = false;

  ImageLayer(this.image) : super(
            flags: LayerFlags.presetBackground | LayerFlags.logicRotatable,
            name: "Image") {
  }

  @override
  Size? calculateSize(Size canvas, TransformData data) =>
      Size(image.dimensions.width * data.scale, image.dimensions.height * data.scale);

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    Widget widget = Image(
      image: image.image,
      width: image.dimensions.width * data.scale,
      height: image.dimensions.height * data.scale,
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

class ImageLayerSerializer extends PicassoLayerSerializer {
  ImageLayerSerializer() : super("picasso:image");

  @override
  bool check(PicassoLayer layer) {
    return layer is ImageLayer;
  }

  @override
  Future<PicassoLayer> deserialize(ByteBuf buf, PicassoCanvasState state,
      PicassoEditorState? editorState) async {
    var flipped = buf.readBool();
    var img = buf.readSizedImage();
    var layer = ImageLayer(img);
    layer.flipped = flipped;
    return layer;
  }

  @override
  Future serialize(
      PicassoLayer layer, ByteBuf buf, PicassoCanvasState state) async {
    var imageLayer = layer as ImageLayer;
    buf.writeBool(imageLayer.flipped);
    await buf.writeSizedImage(imageLayer.image);
  }
}

class _ImageDialog extends StatefulWidget {
  final ImageTool tool;
  final PicassoEditorState state;

  const _ImageDialog({required this.state, required this.tool});

  @override
  State<_ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<_ImageDialog> {
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
                var layer = canvas.findLayerOfType<ImageLayer>();
                layer.flipped = !layer.flipped;
                layer.setDirty(canvas);
              },
              icon: const Icon(Icons.flip)),
          IconButton(
              onPressed: () {
                var layer = canvas.findLayerOfType<ImageLayer>();
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
                var layer = canvas.findLayerOfType<ImageLayer>();
                var transform = canvas.transforms[canvas.indexOf(layer)];
                canvas.updateTransform(
                    layer,
                    transform.copyWith(
                        rotation: transform.rotation - (0.5 * pi)));
                canvas.scheduleRebuild();
              },
              icon: const Icon(Icons.rotate_left)),
        ],
      ),
    );
  }
}
