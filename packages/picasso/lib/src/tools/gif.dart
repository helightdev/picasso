import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:duffer/duffer.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';
import 'package:picasso/picasso.dart';

@experimental
class GifTool extends PicassoTool {
  String? name;
  IconData? icon;
  ImageProvider provider;

  GifTool(this.provider, {this.name, this.icon, super.visible = true});

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) {
    return PicassoToolDisplay(name ?? state.translations.gifName, icon ?? Icons.gif);
  }

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    var gifLayers = state.canvas.findLayersOfType<GifLayer>();
    if (gifLayers.isEmpty) {
      getImageProviderBytes(provider).then((value) async {
        var buffer = await ImmutableBuffer.fromUint8List(value);
        var codec = await PaintingBinding.instance
            .instantiateImageCodecWithSize(buffer);
        var frames = <FrameInfo>[];
        var imageFrames = <ImageInfo>[];
        for (int i = 0; i < codec.frameCount; i++) {
          FrameInfo frame = await codec.getNextFrame();
          frames.add(frame);
          imageFrames.add(ImageInfo(image: frame.image));
        }
        var layer = GifLayer(value, frames, imageFrames);
        layer.associatedTool = this;
        var canvasRect =
            Rect.fromPoints(Offset.zero, state.canvas.canvasSizeOffset);
        var transform = scaleToRatioCover(canvasRect, null, layer, 1.0);
        transform = makeCentered(canvasRect, transform, layer);
        state.canvas.addLayer(layer, transform);
        state.canvas.reorder(state.canvas.indexOf(layer), 0);
      });
    }
  }


  @override
  void lateInitialise(BuildContext context, PicassoEditorState state) {
    state.canvas.findLayersOfType<GifLayer>().forEach((element) {
      element.associatedTool = this;
    });
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    state.widget.dialogFactory
        .showDialog(context, (context) => _GifDialog(state: state));
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

class GifLayer extends PicassoLayer implements RenderDirector {
  Uint8List bytes;
  List<FrameInfo> frames;
  List<ImageInfo> imageFrames;
  int currentFrame;
  bool playing;

  GifLayer(this.bytes, this.frames, this.imageFrames,
      {this.currentFrame = 0, this.playing = false})
      : super(flags: LayerFlags.presetBackground, name: "Gif");

  @override
  Size? calculateSize(Size canvas, TransformData data) {
    var frame = imageFrames[currentFrame];
    return Size(
        frame.image.width * data.scale, frame.image.height * data.scale);
  }

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    var frame = imageFrames[currentFrame];
    if (playing) {
      return Image.memory(
        bytes,
        key: ValueKey("ni-$id"),
        width: frame.image.width * data.scale,
        height: frame.image.height * data.scale,
        fit: BoxFit.fill,
      );
    }
    Widget widget = RawImage(
      image: frame.image,
      width: frame.image.width * data.scale,
      height: frame.image.height * data.scale,
      fit: BoxFit.fill,
    );

    return widget;
  }

  @override
  Future<RenderOutput> render(PicassoCanvasState state, {bool imageOnly = false}) async {
    var saveBuffer = imageOnly ? Unpooled.fixed(0) : await PicassoSaveSystem.instance.save(state);
    img.Image? picture;
    Map<String,dynamic> metadata = {};
    state.showLoading();
    var fallbackRenderer = const FallbackRenderDirector();
    for (var i = 0; i < frames.length; i++) {
      currentFrame = i;
      setDirty(state);
      if (picture == null) {
        var output = await fallbackRenderer.render(state, imageOnly: imageOnly);
        var png = img.decodePng(output.image.readAvailableBytes());
        picture = png;
        metadata = output.metadata;
      } else {
        var output = await fallbackRenderer.render(state, imageOnly: true);
        var png = img.decodePng(output.image.readAvailableBytes());
        picture.addFrame(png);
      }
    }
    state.showLoading();
    var gif = img.encodeGif(picture!);
    state.hideLoading();
    return RenderOutput(saveBuffer, gif.asWrappedBuffer, metadata);
  }
}

class GifLayerSerializer extends PicassoLayerSerializer {
  GifLayerSerializer() : super("picasso:gif");

  @override
  bool check(PicassoLayer layer) => layer is GifLayer;

  @override
  FutureOr<PicassoLayer> deserialize(ByteBuf buf, PicassoCanvasState state,
      PicassoEditorState? editorState) async {
    var curFrame = buf.readInt32();
    var len = buf.readInt32();
    var bytes = buf.readBytes(len);
    var buffer = await ImmutableBuffer.fromUint8List(bytes);
    var codec =
        await PaintingBinding.instance.instantiateImageCodecWithSize(buffer);
    var frames = <FrameInfo>[];
    var imageFrames = <ImageInfo>[];
    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frame = await codec.getNextFrame();
      frames.add(frame);
      imageFrames.add(ImageInfo(image: frame.image));
    }
    var layer = GifLayer(bytes, frames, imageFrames, currentFrame: curFrame);
    if (state.widget.settings.readonly) layer.playing = true;
    return layer;
  }

  @override
  FutureOr<void> serialize(
      PicassoLayer layer, ByteBuf buf, PicassoCanvasState state) {
    var gifLayer = layer as GifLayer;
    buf.writeInt32(gifLayer.currentFrame);
    var bytes = gifLayer.bytes;
    buf.writeInt32(bytes.length);
    buf.writeBytes(bytes);
  }
}

// ignore: must_be_immutable
class _GifDialog extends StatelessWidget {
  final PicassoEditorState state;

  _GifDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      var layer = state.canvas.findLayerOfType<GifLayer>();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildPlayButton(setState, layer),
            ),
            _GifFrameSlider(
              layer: state.canvas.findLayerOfType<GifLayer>(),
              editorState: state,
              inactive: layer.playing,
            )
          ],
        ),
      );
    });
  }

  Widget _buildPlayButton(StateSetter setState, GifLayer layer) {
    if (layer.playing) {
      return OutlinedButton(
          onPressed: () {
            setState(() {
              layer.playing = false;
              layer.setDirty(state.canvas);
            });
          },
          child: Text(state.translations.gifStop));
    }

    return ElevatedButton(
        onPressed: () {
          setState(() {
            layer.playing = true;
            layer.setDirty(state.canvas);
          });
        },
        child: Text(state.translations.gifPlay));
  }
}

class _GifFrameSlider extends StatefulWidget {
  final PicassoEditorState editorState;
  final GifLayer layer;
  final bool inactive;

  const _GifFrameSlider(
      {Key? key,
      required this.inactive,
      required this.layer,
      required this.editorState})
      : super(key: key);

  @override
  State<_GifFrameSlider> createState() => _GifFrameSliderState();
}

class _GifFrameSliderState extends State<_GifFrameSlider> {
  @override
  Widget build(BuildContext context) {
    var frameCount = widget.layer.frames.length;
    return Slider(
        value: widget.layer.currentFrame.toDouble(),
        min: 0.0,
        max: frameCount.toDouble() - 1,
        divisions: frameCount < 32 ? frameCount : null,
        onChanged: widget.inactive
            ? null
            : (val) {
                widget.layer.currentFrame = min(val.round(), frameCount - 1);
                widget.layer.setDirty(widget.editorState.canvas);
                setState(() {});
              });
  }
}
