import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

Widget _noWidgetProvider(double opacity) => const SizedBox();

class FilterTool extends PicassoTool {
  final String? name;
  final IconData icon;
  final FilterPreset nonePreset;
  final List<FilterPreset> presets;

  const FilterTool({
    this.name,
    this.icon = Icons.gradient,
    this.nonePreset = const FilterPreset(
        _noWidgetProvider,
        Icon(
          Icons.close,
          size: 64,
        ),
        "@none"),
    this.presets = const [],
  });

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.filterName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    state.canvas.addLayer(FilterLayer(nonePreset));
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    showModalBottomSheet(
        context: context,
        builder: (context) => _FilterDialog(state: state, tool: this));
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

class FilterLayer extends NonInteractiveCoverLayer {
  double opacity = 1.0;
  FilterPreset preset;

  FilterLayer(this.preset);

  @override
  Widget buildFixed(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    return preset.widgetBuilder(opacity);
  }
}

// ignore: must_be_immutable
class _FilterDialog extends StatelessWidget {
  final FilterTool tool;
  final PicassoEditorState state;

  late List<FilterPreset> presets;

  _FilterDialog({required this.state, required this.tool}) {
    presets = [tool.nonePreset, ...tool.presets];
  }

  Widget buildPresetTile(BuildContext context, int index) {
    var preset = presets[index];
    Widget preview = preset.widgetBuilder(1);
    if (preset.preview != null) {
      preview = preset.preview!;
    }
    var name = preset.name;
    if (name == "@none") {
      name = state.translations.none;
    }
    return _PresetTile(
        name: name,
        preview: preview,
        callback: () {
          var layer = state.canvas.findLayerOfType<FilterLayer>();
          layer.preset = preset;
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
