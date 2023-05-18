import 'dart:async';

import 'package:collection/collection.dart';
import 'package:duffer/duffer.dart';
import 'package:duffer/src/bytebuf_base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

Widget _noWidgetProvider(double opacity) => const SizedBox();

class FilterDataProvider {

  static String key = "picasso:filter";
  
  final FilterPreset defaultPreset;
  final Map<String, FilterPreset> presets;

  const FilterDataProvider({
    this.defaultPreset = const FilterPreset(
        _noWidgetProvider,
        Icon(
          Icons.close,
          size: 64,
        ),
        "@none"),
    this.presets = const {},
  });
}

class FilterTool extends PicassoTool {
  final String? name;
  final IconData icon;

  const FilterTool({
    this.name,
    this.icon = Icons.gradient,
  });

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.filterName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    FilterDataProvider provider = state.canvas.bindings[FilterDataProvider.key];
    state.canvas.getOrCreateLayerOfType<FilterLayer>(() => [FilterLayer(null, provider.defaultPreset, this)]);
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    FilterDataProvider provider = state.canvas.bindings[FilterDataProvider.key];
    state.widget.dialogFactory.showDialog(context, (context) => _FilterDialog(state: state, tool: this, provider: provider,));
  }
}

class FilterLayerSerializer extends PicassoLayerSerializer {
  FilterLayerSerializer() : super("picasso:filter");

  @override
  bool check(PicassoLayer layer) => layer is FilterLayer;

  @override
  FutureOr<PicassoLayer> deserialize(ByteBuf buf, PicassoCanvasState state, PicassoEditorState? editorState) {
    FilterDataProvider provider = state.bindings[FilterDataProvider.key];
    var presetId = buf.readNullable(() => buf.readLPString());
    var preset = presetId == null ? provider.defaultPreset : provider.presets[presetId];
    return FilterLayer(presetId, preset!, editorState?.tools.whereType<FilterTool>().firstOrNull);
  }

  @override
  FutureOr<void> serialize(PicassoLayer layer, ByteBuf buf, PicassoCanvasState state) {
    var filterLayer = layer as FilterLayer;
    buf.writeNullable(filterLayer.presetId, (p0) => buf.writeLPString(p0));
  }
  
}

class FilterPreset {
  final Widget Function(double opacity) widgetBuilder;
  final Widget? preview;
  final String name;

  const FilterPreset(this.widgetBuilder, this.preview, this.name);

  factory FilterPreset.tone(String name, Color color,
      {BlendMode? blendMode = BlendMode.color, Widget? preview}) {
    return FilterPreset(
        (opacity) => Container(
              decoration: BoxDecoration(
                color: color.withOpacity(color.opacity * opacity),
                backgroundBlendMode: blendMode,
              ),
            ),
        preview ??
            Container(
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
            ),
        name);
  }

  factory FilterPreset.linearGradient(String name,
      {required List<Color> colors,
      List<double>? stops,
      BlendMode? blendMode = BlendMode.color,
      AlignmentGeometry begin = Alignment.centerLeft,
      AlignmentGeometry end = Alignment.centerRight,
      TileMode tileMode = TileMode.clamp,
      GradientTransform? transform}) {
    return FilterPreset(
        (opacity) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: colors.map((e) {
                      return e.withOpacity(e.opacity * opacity);
                    }).toList(),
                    stops: stops,
                    begin: begin,
                    end: end,
                    tileMode: tileMode,
                    transform: transform),
                backgroundBlendMode: blendMode,
              ),
            ),
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: colors,
                  stops: stops,
                  begin: begin,
                  end: end,
                  tileMode: tileMode,
                  transform: transform),
              borderRadius: BorderRadius.circular(8)),
        ),
        name);
  }
}

class FilterLayer extends PicassoLayer {
  double opacity = 1.0;
  FilterPreset preset;
  String? presetId;
  FilterTool? tool;

  FilterLayer(this.presetId, this.preset, this.tool): super(flags: LayerFlags.presetScreenspaceCover) {
    name = "Filter Layer";
    associatedTool = tool;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(StringProperty("preset", preset.name));
    properties.add(PercentProperty("opacity", opacity));
  }

  @override
  Widget build(BuildContext context, TransformData data, PicassoCanvasState state) {
    return ConstrainedBox(
      constraints: BoxConstraints.tight(state.canvasSize),
      child: preset.widgetBuilder(opacity),
    );
  }

  @override
  Size calculateSize(Size canvas, TransformData data) => canvas;
}

// ignore: must_be_immutable
class _FilterDialog extends StatelessWidget {
  final FilterTool tool;
  final PicassoEditorState state;
  final FilterDataProvider provider;

  late List<MapEntry<String?, FilterPreset>> presets;

  _FilterDialog({required this.state, required this.tool, required this.provider}) {
    var pm = <String?, FilterPreset>{
      null: provider.defaultPreset
    };
    pm.addAll(provider.presets);
    presets = pm.entries.toList();
  }

  Widget buildPresetTile(BuildContext context, int index) {
    var preset = presets[index];
    Widget preview = preset.value.widgetBuilder(1);
    if (preset.value.preview != null) {
      preview = preset.value.preview!;
    }
    var name = preset.value.name;
    if (name == "@none") {
      name = state.translations.none;
    }
    return _PresetTile(
        name: name,
        preview: preview,
        callback: () {
          var layer = state.canvas.findLayerOfType<FilterLayer>();
          layer.preset = preset.value;
          layer.presetId = preset.key;
          layer.setDirty(state.canvas);
          Navigator.pop(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 128 + 32,
            child: ListView.builder(
              key: const ValueKey(#FilterDialogPresetPreview),
              scrollDirection: Axis.horizontal,
              itemBuilder: buildPresetTile,
              itemCount: presets.length,
            ),
          ),
          _LayerOpacitySlider(
            layer: state.canvas.findLayerOfType<FilterLayer>(),
            editorState: state,
          )
        ],
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
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: callback,
        child: SizedBox(
            width: 128,
            height: 128 + 16 + 4,
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints.tight(const Size(128, 128)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: preview,
                  ),
                ),
                const SizedBox(height: 4),
                Text(name,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onBackground))
              ],
            )),
      ),
    );
  }
}

class _LayerOpacitySlider extends StatefulWidget {
  final PicassoEditorState editorState;
  final FilterLayer layer;

  const _LayerOpacitySlider(
      {Key? key, required this.layer, required this.editorState})
      : super(key: key);

  @override
  State<_LayerOpacitySlider> createState() => _LayerOpacitySliderState();
}

class _LayerOpacitySliderState extends State<_LayerOpacitySlider> {
  @override
  Widget build(BuildContext context) {
    return Slider(
        value: widget.layer.opacity,
        min: 0.0,
        max: 1.0,
        onChanged: (val) {
          widget.layer.opacity = val;
          widget.layer.setDirty(widget.editorState.canvas);
          setState(() {});
        });
  }
}
