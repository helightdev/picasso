
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

import 'default.dart';

class LayerWidget extends StatelessWidget {

  final DefaultCanvasState state;
  final int index;
  final TransformData transform;
  final PicassoLayer layer;

  const LayerWidget(this.state, this.index, this.transform, this.layer, {super.key});

  @override
  Widget build(BuildContext context) {
    if (layer.hidden) return Container();
    var wrapped = layer.buildCached(context, transform, state);
    if (state.selectedLayer == index && state.shadeSelectedLayout) {
      wrapped = Opacity(opacity: 0.5, child: wrapped);
    }
    if (layer.hasFlag(LayerFlags.rotatable) || layer.hasFlag(LayerFlags.logicRotatable)) {
      wrapped = Transform.rotate(angle: transform.rotation, child: wrapped);
    }
    if (layer.hasFlag(LayerFlags.tappable)) {
      wrapped = GestureDetector(
        onTap: () {
          layer.onTap(context, state.transforms[state.indexOf(layer)], state);
        },
        child: wrapped,
      );
    }
    return Positioned(
      left: transform.x,
      top: transform.y,
      child: wrapped,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty("locked", value: layer.locked, defaultValue: false, ifTrue: "locked"));
    properties.add(FlagProperty("hidden", value: layer.hidden, defaultValue: false, ifTrue: "hidden"));
    properties.add(StringProperty("id", layer.id, quoted: false));
    properties.add(StringProperty("name", layer.name, ));
    layer.debugFillProperties(properties);
    properties.add(DiagnosticsBlock(name: "options", properties: [
      FlagProperty("rotatable", value: layer.hasFlag(LayerFlags.rotatable), defaultValue: true, ifFalse: "not rotatable"),
      FlagProperty("movable", value: layer.hasFlag(LayerFlags.movable), defaultValue: true, ifFalse: "not movable"),
      FlagProperty("scalable", value: layer.hasFlag(LayerFlags.scalable), defaultValue: true, ifFalse: "not scalable"),
      FlagProperty("tappable", value: layer.hasFlag(LayerFlags.tappable), defaultValue: true, ifFalse: "not tappable"),
      FlagProperty("promoting", value: layer.hasFlag(LayerFlags.promoting), defaultValue: true, ifFalse: "not promoting"),
      FlagProperty("passthrough", value: layer.hasFlag(LayerFlags.passthrough), defaultValue: false, ifTrue: "passthrough"),
      FlagProperty("deletable", value: layer.hasFlag(LayerFlags.deletable), defaultValue: true, ifFalse: "not deletable"),
      FlagProperty("cover", value: layer.hasFlag(LayerFlags.cover), defaultValue: false, ifTrue: "cover"),
      FlagProperty("snapping", value: layer.hasFlag(LayerFlags.snapping), defaultValue: true, ifFalse: "not snapping"),
      FlagProperty("logicRotatable", value: layer.hasFlag(LayerFlags.logicRotatable), defaultValue: false, ifTrue: "is manually rotatable"),
      FlagProperty("renderable", value: layer.hasFlag(LayerFlags.renderable), defaultValue: true, ifFalse: "no render output"),
      FlagProperty("screenspace", value: layer.hasFlag(LayerFlags.screenspace), defaultValue: false, ifTrue: "screenspace layer")
    ]));

    var transformBuilder = DiagnosticPropertiesBuilder();
    state.transforms[index].debugFillProperties(transformBuilder);
    properties.add(DiagnosticsBlock(name: "transform", properties: transformBuilder.properties));
  }
}
