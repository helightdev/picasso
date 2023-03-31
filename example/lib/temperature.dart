import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

class TemperatureTool extends PicassoTool {
  final String? name;
  final IconData icon;

  const TemperatureTool({
    this.name,
    this.icon = Icons.thermostat,
  });

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) {
    return PicassoToolDisplay(name ?? "Temperature", icon);
  }

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    state.canvas.addLayer(TemperatureLayer());
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    var layer = state.canvas.findLayerOfType<TemperatureLayer>();
    showSingleSliderDialog(context, layer, state, resettable: true);
  }
}

class TemperatureLayer extends NonInteractiveCoverLayer with SingleSliderValue {
  @override
  double value = 0.5;

  TemperatureLayer() {
    name = "Temperature Layer";
  }

  @override
  void reset() {
    value = 0.5;
  }

  @override
  Widget buildFixed(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    // This is not optimal but gets the job done
    if (value == 0.5) return Container();
    if (value > 0.5) {
      var opacity = (value - 0.5) * 0.4;
      return Container(
          decoration: BoxDecoration(
              color: const Color(0xffff6c00).withOpacity(opacity),
              backgroundBlendMode: BlendMode.color));
    } else {
      var opacity = (1 - (value * 2)) * 0.4;
      return Container(
          decoration: BoxDecoration(
              color: const Color(0xffa1bfff).withOpacity(opacity),
              backgroundBlendMode: BlendMode.color));
    }
  }

  @override
  void scheduleRebuild(PicassoCanvasState state) {
    setDirty(state);
  }
}
