import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:duffer/duffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'package:picasso/picasso.dart';
import 'package:picasso/src/canvas/default.dart';

export 'persistence/saving.dart';
export 'persistence/serializable.dart';

void _voidCallback(BuildContext context, PicassoCanvasState state) {}

/// Fixed size editing region of the [PicassoEditor] that can also be used
/// independently from the editor.
class PicassoCanvas extends StatefulWidget {
  final CanvasSettings settings;
  final Function(BuildContext context, PicassoCanvasState state) callback;
  final Map<String, dynamic> bindings;
  final CanvasSaveData? saveData;

  const PicassoCanvas(
      {Key? key,
      required this.settings,
      this.callback = _voidCallback,
      this.bindings = const {},
      this.saveData})
      : super(key: key);

  @override
  State<PicassoCanvas> createState() => DefaultCanvasState();
}

class CanvasSettings {
  double width;
  double height;
  bool snapPosition;
  bool snapRotation;
  bool layerPromotion;
  int rotationSnapPoints;
  Color backgroundColor;
  bool readonly;

  CanvasSettings(
      {required this.width,
      required this.height,
      this.readonly = false,
      this.snapPosition = true,
      this.snapRotation = true,
      this.layerPromotion = true,
      this.rotationSnapPoints = 8,
      this.backgroundColor = Colors.black});

  void write(ByteBuf buf) {
    buf.writeFloat64(width);
    buf.writeFloat64(height);
    buf.writeColor(backgroundColor);
    buf.writeBool(readonly);
    buf.writeBool(layerPromotion);
    buf.writeInt32(rotationSnapPoints);
    buf.writeBool(snapPosition);
    buf.writeBool(snapRotation);
  }

  static CanvasSettings read(ByteBuf buf) {
    var width = buf.readFloat64();
    var height = buf.readFloat64();
    var backgroundColor = buf.readColor();
    var readonly = buf.readBool();
    var layerPromotion = buf.readBool();
    var rotationSnapPoints = buf.readInt32();
    var snapPosition = buf.readBool();
    var snapRotation = buf.readBool();
    return CanvasSettings(
        width: width,
        height: height,
        backgroundColor: backgroundColor,
        readonly: readonly,
        layerPromotion: layerPromotion,
        rotationSnapPoints: rotationSnapPoints,
        snapPosition: snapPosition,
        snapRotation: snapRotation
    );
  }
}

abstract class PicassoCanvasState extends State<PicassoCanvas> {
  /// Returns the actual size of the canvas.
  Size get canvasSize;

  /// Returns all layers of the canvas.
  List<PicassoLayer> get layers;

  /// Returns all transforms associated to their [PicassoLayer] in
  /// [layers] based on their index.
  List<TransformData> get transforms;

  /// Gets the index index of the currently selected [PicassoLayer].
  int? get selectedLayer;

  /// Updates the currently selected [PicassoLayer].
  set selectedLayer(int? value);

  /// Returns if the user is currently dragging a layer.
  bool get isDragging;

  /// Updates [isDragging].
  set isDragging(bool value);

  /// Returns the amount of [layers] on this canvas.
  int get layerCount;

  /// Returns the collected render metadata of the last [performRenderPass].
  Map<String, dynamic> get annotatedRenderData;

  @internal
  bool get skipPickupFeedback;

  @internal
  set skipPickupFeedback(bool value);

  @internal
  GlobalKey get repaintBoundaryKey;

  @internal
  Offset get deleteIconOffset;

  @internal
  set showDeleteIcon(bool value);

  @internal
  set shadeSelectedLayout(bool value);

  /// Adds a [layer] to this canvas.
  void addLayer(PicassoLayer layer, [TransformData? transform]);

  /// Removes a [layer] from this canvas.
  void removeLayer(PicassoLayer layer);

  /// Replaces the transform associated with [layer] with [data].
  void updateTransform(PicassoLayer layer, TransformData data);

  /// Renders the current canvas to a PNG [ByteBuffer] and returns it.
  Future<ByteBuffer> getImage();

  /// Renders the current canvas to a PNG [ByteBuffer] and returns it
  /// while also including the metadata emitted by layers.
  Future<RenderOutput> getRenderOutput({bool imageOnly = false});

  /// Enqueues the given [layer] for a rebuild.
  void rebuildLayer(PicassoLayer layer);

  /// Enqueues all [layers] for a rebuild.
  void rebuildAllLayers();

  /// Forcefully schedules the next rebuild.
  void scheduleRebuild();

  /// Shows the loading indicator.
  void showLoading();

  /// Hides the loading indicator-
  void hideLoading();

  /// Performs a rendering pass excluding all layers which don't have
  /// [PicassoLayer.renderOutput] set to true collect all annotated render
  /// metadata produced by [PicassoLayer.annotateRenderMetadata]
  void performRenderPass(Future Function() callback);
}

extension CanvasStateExtensions on PicassoCanvasState {
  Map<String, dynamic> get bindings => widget.bindings;

  /// Returns the index of [PicassoLayer] inside [layers].
  int indexOf(PicassoLayer layer) => layers.indexOf(layer);

  /// Returns the first layer of type [T].
  T findLayerOfType<T>() {
    assert(T != dynamic, "dynamic is not a valid layer type");
    return layers.firstWhere((element) => element is T) as T;
  }

  /// Returns all layer of type [T].
  List<T> findLayersOfType<T>() {
    assert(T != dynamic, "dynamic is not a valid layer type");
    return layers.whereType<T>().toList();
  }

  /// Gets or creates a layer of type [T] using the [activator] function.
  T getOrCreateLayerOfType<T extends PicassoLayer>(List Function() activator) {
    assert(T != dynamic, "dynamic is not a valid layer type");
    var currentLayer = layers.whereType<T>().firstOrNull;
    if (currentLayer == null) {
      var parts = activator();
      if (parts.length == 1) {
        addLayer(parts[0]);
      } else {
        addLayer(parts[0], parts[1]);
      }
      return parts[0];
    }
    return currentLayer;
  }

  /// Returns the [TransformData] associated with the [layer].
  TransformData transformOf(PicassoLayer layer) {
    var i = indexOf(layer);
    return transforms[i];
  }

  /// Moves [PicassoLayer] and [TransformData] at the index of [layer] to [to].
  void reorderLayer(PicassoLayer layer, int to) {
    reorder(indexOf(layer), to);
  }

  /// Moves [PicassoLayer] and [TransformData] at the index [from] to [to].
  void reorder(int from, int to) {
    if (from < to) {
      to -= 1;
    }
    var l = layers.removeAt(from);
    var t = transforms.removeAt(from);
    layers.insert(to, l);
    transforms.insert(to, t);
    rebuildAllLayers();
    scheduleRebuild();
  }

  /// Returns the size of this canvas as a [Offset].
  Offset get canvasSizeOffset => Offset(canvasSize.width, canvasSize.height);

  /// Returns a [Rect] with the dimensions of this canvas.
  Rect get rect => Rect.fromPoints(Offset.zero, canvasSizeOffset);

  /// Returns the aspect ratio this canvas is using.
  double get aspectRatio => widget.settings.width / widget.settings.height;

  /// Returns the [RenderRepaintBoundary] of this canvas.
  RenderRepaintBoundary get renderRepaintBoundary {
    RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
        .findRenderObject()! as RenderRepaintBoundary;
    return boundary;
  }
}
