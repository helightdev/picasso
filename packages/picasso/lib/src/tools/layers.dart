import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

class LayersTool extends PicassoTool {

  String? name;
  IconData? icon;

  LayersTool({
    this.name,
    this.icon,
  });

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) {
    return PicassoToolDisplay(name ?? state.translations.layersName, icon ?? Icons.layers);
  }

  @override
  void initialise(BuildContext context, PicassoEditorState state) {}

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    state.widget.dialogFactory
        .showDialog(context, (context) => _buildDialog(state));
  }

  StatefulBuilder _buildDialog(PicassoEditorState state) {
    return StatefulBuilder(builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 8),
        child: ReorderableListView.builder(
            reverse: true,
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            header: const SizedBox(
              height: 16,
            ),
            footer: const SizedBox(
              height: 16,
            ),
            itemBuilder: (context, i) {
              var layer = state.canvas.layers[i];
              var transform = state.canvas.transforms[i];
              var widget = layer.build(context, transform, state.canvas);
              var tile = LayerListTile(
                key: ValueKey(layer.id),
                index: i,
                layer: layer,
                preview: widget,
                state: state,
                stateUpdate: () => setState(() {}),
              );
              return tile;
            },
            itemCount: state.canvas.layerCount,
            onReorder: (from, to) {
              state.canvas.reorder(from, to);
              setState(() {});
            }),
      );
    });
  }
}

class LayerListTile extends StatelessWidget {
  const LayerListTile(
      {super.key,
      required this.index,
      required this.state,
      required this.layer,
      required this.preview,
      required this.stateUpdate});

  final int index;
  final PicassoEditorState state;
  final PicassoLayer layer;
  final Widget preview;
  final VoidCallback stateUpdate;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var titleStyle = theme.textTheme.titleSmall
        ?.copyWith(color: theme.colorScheme.onBackground);
    var bodyStyle = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onBackground);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          titleSmall: titleStyle,
          bodySmall: bodyStyle
        ),
        popupMenuTheme: theme.popupMenuTheme.copyWith(
          textStyle: titleStyle,
          labelTextStyle: MaterialStatePropertyAll(titleStyle)
        ),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: OverflowBox(
                alignment: Alignment.center,
                child: preview,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.name,
                      maxLines: 2,
                      style: titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            _buildButtons(context, titleStyle),
            const SizedBox(
              width: 8,
            )
          ],
        ),
      ),
    );
  }

  ButtonBar _buildButtons(BuildContext context, TextStyle? titleStyle) {
    Iterable<PopupMenuEntry<VoidCallback>> layerOptions = [];
    if (layer.associatedTool != null) {
      layerOptions = layer.associatedTool!.getLayerOptions(context, state, layer);
    }

    return ButtonBar(
      children: [
        if (!layer.hasFlag(LayerFlags.passthrough))
          IconButton(
              onPressed: () {
                layer.hidden = !layer.hidden;
                stateUpdate();
                state.canvas.rebuildLayer(layer);
                state.canvas.scheduleRebuild();
              },
              icon:
                  Icon(layer.hidden ? Icons.visibility_off : Icons.visibility)),
        if (!layer.hasFlag(LayerFlags.passthrough))
          IconButton(
              onPressed: () {
                layer.locked = !layer.locked;
                stateUpdate();
                state.canvas.rebuildLayer(layer);
                state.canvas.scheduleRebuild();
              },
              icon: Icon(layer.locked ? Icons.lock_outline : Icons.lock_open)),
        if (layer.hasFlag(LayerFlags.deletable) || layer.hasFlag(LayerFlags.movable) || layerOptions.isNotEmpty)
          PopupMenuButton<VoidCallback>(
            itemBuilder: (context) => <PopupMenuEntry<VoidCallback>>[
              ...layerOptions,
              if (layer.hasFlag(LayerFlags.movable)) PopupMenuItem(
                child: Text(
                  state.translations.layersCenter,
                  style: titleStyle,
                ),
                value: () {
                  var newLocation = makeCentered(state.canvas.rect, state.canvas.transformOf(layer), layer);
                  state.canvas.updateTransform(layer, newLocation);
                  state.canvas.rebuildLayer(layer);
                  state.canvas.scheduleRebuild();
                },
              ),
              if (layer.hasFlag(LayerFlags.deletable)) PopupMenuItem(
                  child: Text(
                    state.translations.layersRemove,
                    style: titleStyle?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                  value: () {
                    state.canvas.removeLayer(layer);
                    state.canvas.rebuildAllLayers();
                    state.canvas.scheduleRebuild();
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      stateUpdate();
                    });
                  },
                ),
            ],
            onSelected: (callback) => callback(),
          ),
        _buildDragHandle()
      ],
    );
  }

  Widget _buildDragHandle() {
    if (layer.hasFlag(LayerFlags.logical)) return Container();
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
        child: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)));
  }
}
