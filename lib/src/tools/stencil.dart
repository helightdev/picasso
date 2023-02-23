import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'package:picasso/src/utils.dart';

class StencilTool extends PicassoTool {
  final String? name;
  final IconData icon;
  final List<StencilPreset> presets;
  final StencilPreset nonePreset;

  const StencilTool(
      {this.name,
      this.icon = Icons.border_style,
      this.presets = const [],
      this.nonePreset = const StencilPreset("@none", null)});

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.stencilName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    state.canvas.addLayer(StencilLayer(nonePreset));
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    showModalBottomSheet(
        context: context,
        builder: (context) => _StencilDialog(state: state, tool: this));
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
  StencilPreset preset;

  StencilLayer(this.preset)
      : super(
            movable: false,
            rotatable: false,
            scalable: false,
            passthrough: true,
            promoting: false,
            deletable: true,
            tappable: false,
            cover: true);

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
}

// ignore: must_be_immutable
class _StencilDialog extends StatelessWidget {
  final StencilTool tool;
  final PicassoEditorState state;

  late List<StencilPreset> presets;

  _StencilDialog({required this.state, required this.tool}) {
    presets = [tool.nonePreset, ...tool.presets];
  }

  Widget buildPresetTile(BuildContext context, int index) {
    var preset = presets[index];
    Widget preview = Container(
      width: 128,
      height: 128,
      alignment: Alignment.center,
      child: const Icon(
        Icons.close,
        size: 64,
      ),
    );
    if (preset.image != null) {
      preview = Image(
          image: preset.image!,
          width: 128,
          height: 128,
          fit: BoxFit.fill,
          loadingBuilder: tileImageLoadingBuilder);
    }
    var name = preset.name;
    if (name == "@none") {
      name = state.translations.none;
    }
    return _PresetTile(
        name: name,
        preview: preview,
        callback: () {
          var layer = state.canvas.findLayerOfType<StencilLayer>();
          layer.preset = preset;
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
