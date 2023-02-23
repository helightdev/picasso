import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picasso/picasso.dart';
import 'package:picasso/src/utils.dart';

mixin CanvasGestureMixin on PicassoCanvasState {
  @override
  int? selectedLayer;
  @override
  bool isDragging = false;
  @override
  bool shadeSelectedLayout = false;

  //region Temporary Gesture Data
  late Offset _lastFocalPos;
  late Size _initialSize;
  late double _xStart;
  late double _yStart;
  late double _xValue;
  late double _yValue;
  late double _scaleValue;
  late double _rotationValue;

  //endregion
  //region Snapping
  double _lastSnappedRotation = double.maxFinite;
  bool _snappedXAxis = false;
  bool _snappedYAxis = false;
  late List<double> snapAngles;

  void _setSnapAngles(int count) {
    var angles = <double>[];
    var angleCount = count;
    var stepValue = tau / angleCount;
    var x = 0.0;
    for (var i = 0; i < angleCount; i++) {
      x += stepValue;
      angles.add(x);
    }
    snapAngles = angles;
  }

  double snapRotation(double angle, PicassoLayer layer,
      {double tolerance = 0.125, bool haptic = true}) {
    if (!widget.settings.snapRotation || !layer.snapping) return angle;
    var normalized = angle % tau;
    if (normalized < 0) return tau - normalized;

    for (var value in snapAngles) {
      var dist = (normalized - value).abs();
      if (dist < tolerance) {
        if (_lastSnappedRotation != value) {
          HapticFeedback.selectionClick();
          _lastSnappedRotation = value;
        }
        return value;
      }
    }
    _lastSnappedRotation = double.maxFinite;
    return normalized;
  }

  TransformData snapPosition(PicassoLayer layer, TransformData transform,
      {double tolerance = 16}) {
    if (!widget.settings.snapPosition || !layer.snapping) return transform;
    var size = layer.calculateSize(canvasSize, transform) ?? Size.zero;
    var rect = Rect.fromPoints(
        Offset.zero, Offset(canvasSize.width, canvasSize.height));
    var anchor =
        Offset(transform.x + (size.width / 2), transform.y + (size.height / 2));
    var center = rect.center;
    var xAxisDif = (center.dx - anchor.dx).abs();
    var yAxisDif = (center.dy - anchor.dy).abs();
    var x = transform.x;
    var y = transform.y;
    if (xAxisDif < tolerance) {
      x = center.dx - (size.width / 2);
      if (!_snappedXAxis) {
        HapticFeedback.selectionClick();
        _snappedXAxis = true;
      }
    } else {
      _snappedXAxis = false;
    }
    if (yAxisDif < tolerance) {
      y = center.dy - (size.height / 2);
      if (!_snappedYAxis) {
        HapticFeedback.selectionClick();
        _snappedYAxis = true;
      }
    } else {
      _snappedYAxis = false;
    }
    return transform.copyWith(x: x, y: y);
  }

  //endregion

  @override
  void initState() {
    _setSnapAngles(widget.settings.rotationSnapPoints);
    super.initState();
  }

  //region Gesture Handlers
  void handlePointerScale(Offset globalPosition, double delta) {
    delta = delta * -1;
    var entry = getNegotiatedPointerEntry(globalPosition);
    if (entry == null) return;
    handleScaleStart(
        ScaleStartDetails(
          focalPoint: globalPosition,
          pointerCount: 2,
        ),
        true);
    handleScaleUpdate(
        ScaleUpdateDetails(
            focalPoint: globalPosition,
            pointerCount: 2,
            scale: delta > 0 ? 1.1 : 0.9,
            rotation: 0),
        true);
    handleScaleEnd(ScaleEndDetails(pointerCount: 2));
  }

  void handlePointerRotate(Offset globalPosition, double delta) {
    var entry = getNegotiatedPointerEntry(globalPosition);
    if (entry == null) return;
    handleScaleStart(
        ScaleStartDetails(
          focalPoint: globalPosition,
          pointerCount: 2,
        ),
        true);
    var rotValue = tau / 32;
    handleScaleUpdate(
        ScaleUpdateDetails(
          focalPoint: globalPosition,
          pointerCount: 2,
          scale: 1,
          rotation: delta > 0 ? rotValue : -rotValue,
        ),
        true);
    handleScaleEnd(ScaleEndDetails(pointerCount: 2), true);
  }

  void handleScaleStart(ScaleStartDetails details,
      [bool smallPointer = false]) {
    var focalPoint = renderRepaintBoundary.globalToLocal(details.focalPoint);
    var matches = <GestureNegotiationEntry>[];
    for (var i = layerCount - 1; i >= 0; i--) {
      var layer = layers[i];
      if (layer.passthrough) continue;
      var transform = transforms[i];
      var size = layer.calculateSize(canvasSize, transform) ?? const Size(1, 1);
      var layerRect = Rect.fromPoints(Offset(transform.x, transform.y),
          Offset(transform.x + size.width, transform.y + size.height));
      if (layerRect.contains(focalPoint)) {
        matches.add(GestureNegotiationEntry(i, 0, layer));
        continue;
      }
      var radiusPoint =
          Rect.fromCircle(center: focalPoint, radius: smallPointer ? 8 : 32);
      if (layerRect.overlaps(radiusPoint)) {
        var offset = Offset(focalPoint.dx - layerRect.center.dx,
            focalPoint.dy - layerRect.center.dy);
        matches.add(GestureNegotiationEntry(i, offset.distance, layer));
      }
    }
    matches.sorted((a, b) => a.dist.compareTo(b.dist));
    if (matches.isNotEmpty) {
      selectedLayer = matches.first.index;
      _performScaleStart(details, smallPointer);
    }
  }

  void _performScaleStart(ScaleStartDetails details,
      [bool smallPointer = false]) {
    shadeSelectedLayout = false;
    isDragging = true;
    HapticFeedback.selectionClick();
    var transform = transforms[selectedLayer!];
    var layer = layers[selectedLayer!];
    _initialSize =
        layers[selectedLayer!].calculateSize(canvasSize, transform) ??
            Size.zero;
    _lastFocalPos = details.focalPoint;
    _xStart = details.focalPoint.dx;
    _yStart = details.focalPoint.dy;
    _xValue = transform.x;
    _yValue = transform.y;
    _scaleValue = transform.scale;
    _rotationValue = transform.rotation;

    if (layer.promoting) {
      removeLayer(layer);
      addLayer(layer, transform);
      selectedLayer = indexOf(layer);
    }
  }

  void handleScaleUpdate(ScaleUpdateDetails details,
      [bool smallPointer = false]) {
    _lastFocalPos = details.focalPoint;
    var isSingleMove = details.pointerCount == 1;
    if (selectedLayer != null) {
      var transform = transforms[selectedLayer!];
      var layer = layers[selectedLayer!];
      var movedTransform = transform.copyWith(
          scale: layer.scalable ? _scaleValue * details.scale : _scaleValue,
          rotation: layer.rotatable
              ? snapRotation(_rotationValue + details.rotation, layer)
              : _rotationValue,
          x: layer.movable
              ? _xValue + (details.focalPoint.dx - _xStart)
              : _xValue,
          y: layer.movable
              ? _yValue + (details.focalPoint.dy - _yStart)
              : _yValue);
      if (layer.movable) movedTransform = snapPosition(layer, movedTransform);
      var sizeAfter =
          layer.calculateSize(canvasSize, movedTransform) ?? Size.zero;
      var dx = (sizeAfter.width - _initialSize.width) / 2;
      var dy = (sizeAfter.height - _initialSize.height) / 2;
      var adjustedTransform = !layer.scalable
          ? movedTransform
          : movedTransform.copyWith(
              x: movedTransform.x - dx, y: movedTransform.y - dy);

      if (layer.cover && layer.movable) {
        var canvasRect = Rect.fromPoints(Offset.zero, canvasSizeOffset);
        var layerRect = Rect.fromPoints(
            adjustedTransform.offset,
            adjustedTransform.offset
                .translate(sizeAfter.width, sizeAfter.height));

        if (layerRect.contains(canvasRect.topLeft) &&
            layerRect.contains(canvasRect.bottomRight)) {
          updateTransform(layer, adjustedTransform);
        } else {
          if (isSingleMove) {
            var cl = layerRect.contains(canvasRect.centerLeft);
            var cr = layerRect.contains(canvasRect.centerRight);
            var ct = layerRect.contains(canvasRect.topCenter);
            var cb = layerRect.contains(canvasRect.bottomCenter);
            if (!cl && ct && cb || !cr && ct && cb) {
              updateTransform(
                  layer, adjustedTransform.copyWith(x: transform.x));
            } else if (!ct && cl && cr || !cb && cl && cr) {
              updateTransform(
                  layer, adjustedTransform.copyWith(y: transform.y));
            }
          }
        }
      } else {
        updateTransform(layer, adjustedTransform);
      }

      if (layer.deletable) {
        if (isSingleMove) {
          showDeleteIcon = true;
        } else {
          showDeleteIcon = false;
        }

        Rect trashRect = Rect.fromCircle(
            center: deleteIconOffset, radius: smallPointer ? 8 : 32);
        Rect layerRect = Rect.fromCircle(
            center: renderRepaintBoundary.globalToLocal(_lastFocalPos),
            radius: 16);
        if (trashRect.overlaps(layerRect)) {
          shadeSelectedLayout = true;
        } else {
          shadeSelectedLayout = false;
        }
      }
      setState(() {});
    } else {
      shadeSelectedLayout = false;
    }
  }

  void handleScaleEnd(ScaleEndDetails details, [bool smallPointer = false]) {
    if (selectedLayer != null) {
      isDragging = false;
      var layer = layers[selectedLayer!];

      if (layer.deletable) {
        Rect trashRect = Rect.fromCircle(
            center: deleteIconOffset, radius: smallPointer ? 8 : 32);
        Rect layerRect = Rect.fromCircle(
            center: renderRepaintBoundary.globalToLocal(_lastFocalPos),
            radius: 16);
        if (trashRect.overlaps(layerRect)) {
          removeLayer(layer);
          selectedLayer = null;
          HapticFeedback.heavyImpact();
          setState(() {});
        }
      }

      showDeleteIcon = false;
      selectedLayer = null;
      setState(() {});
    }
  }

  GestureNegotiationEntry? getNegotiatedPointerEntry(Offset pos) {
    var focalPoint = renderRepaintBoundary.globalToLocal(pos);
    var matches = <GestureNegotiationEntry>[];
    for (var i = layerCount - 1; i >= 0; i--) {
      var layer = layers[i];
      if (layer.passthrough) continue;
      var transform = transforms[i];
      var size = layer.calculateSize(canvasSize, transform) ?? const Size(1, 1);
      var layerRect = Rect.fromPoints(Offset(transform.x, transform.y),
          Offset(transform.x + size.width, transform.y + size.height));
      if (layerRect.contains(focalPoint)) {
        matches.add(GestureNegotiationEntry(i, 0, layer));
        continue;
      }
      var radiusPoint = Rect.fromCircle(center: focalPoint, radius: 8);
      if (layerRect.overlaps(radiusPoint)) {
        var offset = Offset(focalPoint.dx - layerRect.center.dx,
            focalPoint.dy - layerRect.center.dy);
        matches.add(GestureNegotiationEntry(i, offset.distance, layer));
      }
    }
    matches.sorted((a, b) => a.dist.compareTo(b.dist));
    return matches.firstOrNull;
  }

//endregion
}

class GestureNegotiationEntry {
  int index;
  double dist;
  PicassoLayer layer;

  GestureNegotiationEntry(this.index, this.dist, this.layer);
}
