import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'package:picasso/picasso.dart';
import 'package:picasso/src/canvas/default.dart';

void _voidCallback(BuildContext context, PicassoCanvasState state) {}

/// Fixed size editing region of the [PicassoEditor] that can also be used
/// independently from the editor.
class PicassoCanvas extends StatefulWidget {
  final CanvasSettings settings;
  final Function(BuildContext context, PicassoCanvasState state) callback;

  const PicassoCanvas(
      {Key? key, required this.settings, this.callback = _voidCallback})
      : super(key: key);

  @override
  State<PicassoCanvas> createState() => DefaultCanvasState();
}

class CanvasSettings {
  final double width;
  final double height;
  final bool snapPosition;
  final bool snapRotation;
  final int rotationSnapPoints;
  final Color backgroundColor;

  const CanvasSettings(
      {required this.width,
      required this.height,
      this.snapPosition = true,
      this.snapRotation = true,
      this.rotationSnapPoints = 8,
      this.backgroundColor = Colors.black});
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

  /// Returns the index of [PicassoLayer] inside [layers].
  int indexOf(PicassoLayer layer) => layers.indexOf(layer);

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
  Future<RenderOutput> getRenderOutput();

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

  /// Returns the first layer of type [T].
  T findLayerOfType<T>() {
    return layers.firstWhere((element) => element is T) as T;
  }

  /// Returns all layer of type [T].
  List<T> findLayersOfType<T>() {
    return layers.whereType<T>().toList();
  }

  TransformData transformOf(PicassoLayer layer) {
    var i = indexOf(layer);
    return transforms[i];
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

class RenderOutput {
  final ByteBuffer image;
  final Map<String, dynamic> metadata;

  RenderOutput(this.image, this.metadata);
}
