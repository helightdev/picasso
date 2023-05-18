import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:picasso/picasso.dart';
import 'package:uuid/uuid.dart';

class LayerFlags {
  LayerFlags._();

  /// Defines if the layer's rotation is modifiable by user gestures.
  /// If true, the layers widget will be put inside a [Transform] widget.
  static final int rotatable =           int.parse("1000000000000000", radix: 2);
  /// Forces the canvas to wrap the layer in a [Transform] widget, even if
  /// [rotatable] is disabled.
  static final int logicRotatable =      int.parse("0100000000000000", radix: 2);
  /// Defines if this layer's position is modifiable by user gestures.
  static final int movable =             int.parse("0010000000000000", radix: 2);
  /// Defines if this layer's scale is modifiable by user gestures.
  static final int scalable =            int.parse("0001000000000000", radix: 2);
  /// Modifies if this layer reacts to tap events received by the parent.
  /// If true, the resulting widget will be wrapped by an gesture detector
  /// automatically.
  static final int tappable =            int.parse("0000100000000000", radix: 2);
  /// Layers which are promotable will be put on the top of the stack when
  /// they are picked up by a user gesture. If this option is disabled, the
  /// layer will stay at its stack location even when picked up.
  static final int promoting =           int.parse("0000010000000000", radix: 2);
  /// Makes this layer not participate in gesture operations.
  static final int passthrough =         int.parse("0000001000000000", radix: 2);
  /// Allows this layer to be deleted by dragging the layer to the delete icon.
  /// This option does also work even if the layer itself is not [movable].
  /// Also hides the [PicassoCanvasState.showDeleteIcon] when disabled.
  static final int deletable =           int.parse("0000000100000000", radix: 2);
  /// Allows layer transformation operations only, if the layer still fully
  /// covers the entire canvas, not revealing any background behind the layer.
  ///
  /// The most common use-case is a transformable background layer.
  static final int cover =               int.parse("0000000010000000", radix: 2);
  /// Defines if transformations of this layer can use snap guides.
  static final int snapping =            int.parse("0000000001000000", radix: 2);
  /// Marks a layer as purely logical disabling any rendering for it.
  static final int logical =             int.parse("0000000000100000", radix: 2);
  /// Defines if this layer will be included in the final render pass.
  static final int renderable =          int.parse("0000000000010000", radix: 2);
  /// Defines if a layer is dependent on the flutter layouting.
  /// This will disable caching of the layer widget for this layer.
  static final int screenspace =         int.parse("0000000000001000", radix: 2);

  /// rotatable, movable, scalable, tappable, promoting, deletable, snapping, renderable
  static final int presetDefault = rotatable | movable | scalable |
      tappable | promoting | deletable | snapping | renderable;

  static final int presetBackground = movable | scalable | cover | renderable;

  /// passthrough, renderable, cover
  static final int presetNotInteractive = passthrough | renderable;

  /// passthrough, renderable, cover
  static final int presetNotInteractiveCover = passthrough | renderable | cover;
  
  /// passthrough, renderable, cover, screenspace
  static final int presetScreenspaceCover = passthrough | renderable | cover | screenspace;
}

abstract class PicassoLayer {

  int flags = 0;
  
  bool hasFlag(int mask) {
    return flags & mask == mask;
  }

  // The tool associated with this layer.
  PicassoTool? associatedTool;

  PicassoLayer({
    int? flags,
    this.associatedTool,
    String? name,
  }) {
    this.flags = flags ?? LayerFlags.presetDefault;
    id = const Uuid().v4();
    this.name = name ?? id;
  }

  late String id;

  /// The name of this layer
  late String name;

  bool locked = false;
  bool hidden = false;

  /// Defines if this widget layer should rebuild its widget and omit
  /// the current cached widget.
  bool isDirty = true;

  double _previousScale = double.maxFinite;
  Widget? _cachedWidget;

  /// Requires the give [state] to rebuild this layer.
  @nonVirtual
  void setDirty(PicassoCanvasState state) {
    isDirty = true;
    state.rebuildLayer(this);
    state.scheduleRebuild();
  }

  /// Build method for this layer.
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state);

  /// Returns the size of this layers widget relative to its [TransformData]
  /// and the size of the [canvas]. Can return null if no size can be
  /// determined.
  Size? calculateSize(Size canvas, TransformData data) => null;

  /// Emits additional metadata of this layer which is included in the render
  /// output.
  ///
  /// This can be used output information which will not be present
  /// in the final rendered image but rather added at a later point in time
  /// by an implementing app. This could be used to create Instagram-like
  /// interactive story widgets like polls, location widgets, etc.
  void annotateRenderMetadata(
      PicassoCanvasState state, Map<String, dynamic> metadata) {}

  /// Returns a cached image created by [build] if it is still valid. Otherwise
  /// performs a normal [build] call and returns the result after caching it.
  @nonVirtual
  Widget buildCached(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    if (hasFlag(LayerFlags.scalable) && data.scale != _previousScale) isDirty = true;
    if (isDirty || hasFlag(LayerFlags.screenspace)) {
      isDirty = false;
      _cachedWidget = build(context, data, state);
      _previousScale = data.scale;
    }
    return _cachedWidget!;
  }

  /// Handles tap events pass down to the layer by the [PicassoCanvas].
  void onTap(
      BuildContext context, TransformData data, PicassoCanvasState state) {}

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

/// Information about the position, rotation and scale of a [PicassoLayer].
class TransformData {
  /// X position of a [PicassoLayer] (left -> right).
  final double x;

  /// Y position of a [PicassoLayer] (top -> bottom)
  final double y;

  /// Uniform scale of a [PicassoLayer].
  final double scale;

  /// Rotation of a [PicassoLayer].
  final double rotation;

  /// Returns the [x] and [y] coordinates combined into a [Offset].
  Offset get offset => Offset(x, y);

  TransformData rescale(double s) {
    return TransformData(
        x: x * s, y: y * s, scale: scale * s, rotation: rotation);
  }

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(DoubleProperty("x", x));
    properties.add(DoubleProperty("y", x));
    properties.add(DoubleProperty("scale", x, defaultValue: 1.0));
    properties.add(DoubleProperty("rotation", x, defaultValue: 0.0));
  }

//<editor-fold desc="Data Methods">
  const TransformData({
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransformData &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          scale == other.scale &&
          rotation == other.rotation);

  @override
  int get hashCode =>
      x.hashCode ^ y.hashCode ^ scale.hashCode ^ rotation.hashCode;

  @override
  String toString() {
    return 'TransformData{x: $x, y: $y, scale: $scale, rotation: $rotation}';
  }

  TransformData copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    return TransformData(
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
    };
  }

  factory TransformData.fromMap(Map<String, dynamic> map) {
    return TransformData(
      x: map['x'] as double,
      y: map['y'] as double,
      scale: map['scale'] as double,
      rotation: map['rotation'] as double,
    );
  }
//</editor-fold>
}

class TestGradientLayer extends PicassoLayer {
  TestGradientLayer() : super();
  int i = 0;

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    i++;
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.red, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      width: 64 * data.scale,
      height: 64 * data.scale,
      child: Text(i.toString()),
    );
  }

  @override
  Size? calculateSize(Size canvas, TransformData data) =>
      Size(data.scale * 64, data.scale * 64);

  @override
  void onTap(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    i = 0;
    setDirty(state);
  }
}

abstract class NonInteractiveCoverLayer extends PicassoLayer {
  NonInteractiveCoverLayer()
      : super(flags: LayerFlags.presetNotInteractiveCover);

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    return ConstrainedBox(
      constraints: BoxConstraints.tight(state.canvasSize),
      child: buildFixed(context, data, state),
    );
  }

  Widget buildFixed(
      BuildContext context, TransformData data, PicassoCanvasState state);

  @override
  Size? calculateSize(Size canvas, TransformData data) => canvas;
}
