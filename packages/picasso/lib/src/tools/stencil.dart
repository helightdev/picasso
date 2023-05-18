import 'dart:async';

import 'package:duffer/duffer.dart';
import 'package:duffer/src/bytebuf_base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'package:picasso/src/utils.dart';

class StencilDataProvider {

  static String key = "picasso:stencil";

  final StencilPreset defaultPreset;
  final Map<String, StencilPreset> presets;

  const StencilDataProvider({
    this.defaultPreset = const StencilPreset("@none", null),
    this.presets = const {},
  });
}

class StencilTool extends PicassoTool {
  final String? name;
  final IconData icon;
  const StencilTool(
      {this.name,
      this.icon = Icons.border_style});

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.stencilName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    StencilDataProvider provider = state.canvas.bindings[StencilDataProvider.key];
    state.canvas.getOrCreateLayerOfType<StencilLayer>(() => [StencilLayer(null, provider.defaultPreset)]);
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    state.widget.dialogFactory.showDialog(context, (context) => _StencilDialog(state: state, tool: this));
  }

}

class StencilLayerSerializer extends PicassoLayerSerializer {
  StencilLayerSerializer() : super("picasso:stencil");

  @override
  bool check(PicassoLayer layer) => layer is StencilLayer;

  @override
  FutureOr<PicassoLayer> deserialize(ByteBuf buf, PicassoCanvasState state, PicassoEditorState? editorState) {
    StencilDataProvider provider = state.bindings[StencilDataProvider.key];
    var presetId = buf.readNullable(() => buf.readLPString());
    var preset = presetId == null ? provider.defaultPreset : provider.presets[presetId];
    return StencilLayer(presetId, preset!);
  }

  @override
  FutureOr<void> serialize(PicassoLayer layer, ByteBuf buf, PicassoCanvasState state) {
    var stencilLayer = layer as StencilLayer;
    buf.writeNullable(stencilLayer.presetId, (p0) => buf.writeLPString(p0));
  }
}

class StencilPreset {
  final String name;
  final ImageProvider? image;

  const StencilPreset(this.name, this.image);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StencilPreset &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class StencilLayer extends PicassoLayer {

  String? presetId;
  StencilPreset preset;

  StencilLayer(this.presetId, this.preset)
      : super(
            flags: LayerFlags.presetScreenspaceCover,
    name: "Stencil Layer"
  );

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    if (preset.image == null) return Container();
    return Image(
        image: preset.image!,
        width: state.canvasSize.width,
        height: state.canvasSize.height,
        fit: BoxFit.fill);
  }

  @override
  Size? calculateSize(Size canvas, TransformData data) => canvas;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(StringProperty("preset", preset.name));
  }
}

// ignore: must_be_immutable
class _StencilDialog extends StatelessWidget {
  final StencilTool tool;
  final PicassoEditorState state;

  late List<MapEntry<String?, StencilPreset>> presets;

  _StencilDialog({required this.state, required this.tool}) {
    StencilDataProvider provider = state.canvas.bindings[StencilDataProvider.key];
    var pm = <String?, StencilPreset>{
      null: provider.defaultPreset
    };
    pm.addAll(provider.presets);
    presets = pm.entries.toList();
  }

  Widget buildPresetTile(BuildContext context, int index) {
    var entry = presets[index];
    Widget preview = Container(
      width: 128,
      height: 128,
      alignment: Alignment.center,
      child: const Icon(
        Icons.close,
        size: 64,
      ),
    );
    if (entry.value.image != null) {
      preview = Image(
          image: entry.value.image!,
          width: 128,
          height: 128,
          fit: BoxFit.fill,
          loadingBuilder: tileImageLoadingBuilder);
    }
    var name = entry.value.name;
    if (name == "@none") {
      name = state.translations.none;
    }
    return _PresetTile(
        name: name,
        preview: preview,
        callback: () {
          var layer = state.canvas.findLayerOfType<StencilLayer>();
          layer.preset = entry.value;
          layer.presetId = entry.key;
          layer.setDirty(state.canvas);
          Navigator.pop(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        height: 128 + 32,
        child: ListView.builder(
          key: const ValueKey(#StencilDialogPresetPreview),
          scrollDirection: Axis.horizontal,
          itemBuilder: buildPresetTile,
          itemCount: presets.length,
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String name;
  final Widget preview;
  final void Function() callback;

  const _PresetTile(
      {Key? key,
      required this.name,
      required this.preview,
      required this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: callback,
        child: SizedBox(
            width: 128,
            height: 128 + 16 + 4,
            child: Column(
              children: [
                preview,
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onBackground),
                )
              ],
            )),
      ),
    );
  }
}
