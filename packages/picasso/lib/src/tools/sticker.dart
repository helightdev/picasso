import 'package:collection/collection.dart';
import 'package:duffer/src/bytebuf_base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'package:picasso/src/utils.dart';

import '../persistence/serializable.dart';

class StickerTool extends PicassoTool {
  final String? name;
  final IconData icon;
  final List<SizedImage> presets;

  const StickerTool(
      {this.name, this.icon = Icons.sticky_note_2, required this.presets});

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.stickerName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {}

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    state.widget.dialogFactory.showDialog(context, (context) => _StickerDialog(state: state, tool: this));
  }
}

class StickerLayer extends PicassoLayer {
  final SizedImage sticker;
  final StickerTool? tool;

  StickerLayer(this.sticker, this.tool) : super() {
    name = "Sticker $id";
    associatedTool = tool;
  }

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    return Image(
        image: sticker.image,
        width: sticker.dimensions.width * data.scale,
        height: sticker.dimensions.height * data.scale,
        fit: BoxFit.cover);
  }

  @override
  Size? calculateSize(Size canvas, TransformData data) => Size(
      sticker.dimensions.width * data.scale,
      sticker.dimensions.height * data.scale);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(DoubleProperty("width", sticker.dimensions.width));
    properties.add(DoubleProperty("height", sticker.dimensions.height));
  }
}

class StickerLayerSerializer extends PicassoLayerSerializer {
  StickerLayerSerializer() : super("picasso:sticker");

  @override
  bool check(PicassoLayer layer) {
    return layer is StickerLayer;
  }

  @override
  PicassoLayer deserialize(ByteBuf buf, PicassoCanvasState state, PicassoEditorState? editorState) {
    var sticker = buf.readSizedImage();
    return StickerLayer(sticker, editorState?.tools.whereType<StickerTool>().firstOrNull);
  }

  @override
  Future serialize(PicassoLayer layer, ByteBuf buf, PicassoCanvasState state) async {
    var stickerLayer = layer as StickerLayer;
    await buf.writeSizedImage(stickerLayer.sticker);
  }
}

class _StickerDialog extends StatelessWidget {
  final StickerTool tool;
  final PicassoEditorState state;

  const _StickerDialog({required this.state, required this.tool});

  Widget buildPresetTile(BuildContext context, int index) {
    var preset = tool.presets[index];
    Widget preview = Image(
        image: preset.image,
        width: 128,
        height: 128,
        fit: BoxFit.contain,
        loadingBuilder: tileImageLoadingBuilder);
    return _StickerTile(
        preview: preview,
        callback: () {
          var layer = StickerLayer(preset, tool);
          var canvasRect =
              Rect.fromPoints(Offset.zero, state.canvas.canvasSizeOffset);
          var transform = scaleToRatioContain(
              canvasRect,
              const TransformData(x: 0, y: 0, scale: 1, rotation: 0),
              layer,
              0.2);
          transform = makeCentered(canvasRect, transform, layer);
          state.canvas.addLayer(layer, transform);
          Navigator.pop(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        height: 128,
        child: ListView.builder(
          key: const ValueKey(#StickerDialogPresetPreview),
          scrollDirection: Axis.horizontal,
          itemBuilder: buildPresetTile,
          itemCount: tool.presets.length,
        ),
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  final Widget preview;
  final void Function() callback;

  const _StickerTile({Key? key, required this.preview, required this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: callback,
        child: Container(
          width: 128,
          height: 128,
          alignment: Alignment.center,
          child: preview,
        ),
      ),
    );
  }
}
