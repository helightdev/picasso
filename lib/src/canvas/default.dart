import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:picasso/picasso.dart';
import 'package:picasso/src/canvas/gestures.dart';
import 'package:picasso/src/canvas/visual.dart';

class DefaultCanvasState extends PicassoCanvasState
    with TickerProviderStateMixin, CanvasGestureMixin, CanvasVisualsMixin {
  bool doRebuildAll = true;
  Set<int> scheduledRebuilds = {};
  List<Widget>? cachedLayers;
  bool isInitialised = false;
  bool isMouse = false;

  bool isRenderPass = false;
  late Map<String, dynamic> annotatedRenderData;
  late Future Function() renderPassCallback;

  @override
  final GlobalKey repaintBoundaryKey = GlobalKey();
  @override
  Size canvasSize = Size.zero;
  @override
  bool skipPickupFeedback = false;
  @override
  final List<PicassoLayer> layers = [];
  @override
  final List<TransformData> transforms = [];
  @override
  int get layerCount => layers.length;

  //region Layer Methods
  @override
  int indexOf(PicassoLayer layer) => layers.indexOf(layer);

  @override
  void addLayer(PicassoLayer layer, [TransformData? transform]) {
    layers.add(layer);
    var initialData = TransformData(
        x: canvasSize.width / 2,
        y: canvasSize.height / 2,
        scale: 1,
        rotation: 0);
    var preferredSize =
        layer.calculateSize(canvasSize, initialData) ?? Size.zero;
    var transformData = transform ??
        initialData.copyWith(
            x: initialData.x - (preferredSize.width / 2),
            y: initialData.y - (preferredSize.height / 2));
    transforms.add(transformData);
    rebuildAllLayers();
    scheduleRebuild();
  }

  @override
  void removeLayer(PicassoLayer layer) {
    var index = indexOf(layer);
    layers.removeAt(index);
    transforms.removeAt(index);
    rebuildAllLayers();
    scheduleRebuild();
  }

  @override
  void updateTransform(PicassoLayer layer, TransformData data) {
    var index = indexOf(layer);
    transforms[index] = data;
    rebuildLayer(layer);
  }

  @override
  void rebuildAllLayers() {
    doRebuildAll = true;
  }

  @override
  void rebuildLayer(PicassoLayer layer) {
    scheduledRebuilds.add(indexOf(layer));
  }
  //endregion

  //region Build Methods
  @override
  Widget build(BuildContext context) {
    if (isRenderPass) {
      isRenderPass = false;
      List<Widget> layerWidgets = [];
      var data = <String, dynamic>{};
      for (var i = 0; i < layerCount; i++) {
        var layer = layers[i];
        if (layer.renderOutput && !layer.logical) {
          var widget = _buildLayer(context, i, layer);
          layerWidgets.add(widget);
        }
        layer.annotateRenderMetadata(this, data);
      }
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        renderPassCallback.call().then((value) {
          rebuildAllLayers();
          scheduleRebuild();
        });
      });
      return AspectRatio(
          aspectRatio: aspectRatio, child: _buildInner(layerWidgets));
    }

    if (doRebuildAll) {
      cachedLayers = _buildLayers(context).toList();
      doRebuildAll = false;
      scheduledRebuilds.clear();
    } else if (scheduledRebuilds.isNotEmpty) {
      for (var i in scheduledRebuilds) {
        cachedLayers![i] = _buildLayer(context, i, layers[i]);
      }
    }

    if (cachedLayers == null) {
      rebuildAllLayers();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
      return Container();
    }

    return AspectRatio(
        aspectRatio: aspectRatio,
        child: MouseRegion(
          onEnter: (_) {
            isMouse = true;
          },
          onExit: (_) {
            isMouse = false;
          },
          child: Listener(
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                if (RawKeyboard.instance.keysPressed
                    .contains(LogicalKeyboardKey.shiftLeft)) {
                  handlePointerScale(signal.position, signal.scrollDelta.dy);
                } else if (RawKeyboard.instance.keysPressed
                    .contains(LogicalKeyboardKey.altLeft)) {
                  handlePointerRotate(signal.position, signal.scrollDelta.dy);
                }
              }
            },
            child: GestureDetector(
              onScaleStart: (details) => handleScaleStart(details, isMouse),
              onScaleUpdate: (details) => handleScaleUpdate(details, isMouse),
              onScaleEnd: (details) => handleScaleEnd(details, isMouse),
              child: _buildInner(),
            ),
          ),
        ));
  }

  LayoutBuilder _buildInner([List<Widget>? widgetOverrides]) {
    return LayoutBuilder(builder: (context, constraints) {
      canvasSize = constraints.biggest;
      if (!isInitialised) {
        isInitialised = true;
        widget.callback(context, this);
        scheduleRebuild();
      }
      deleteIconOffset = Offset((canvasSize.width / 2), canvasSize.height - 32);
      return RepaintBoundary(
          key: repaintBoundaryKey,
          child: _buildStack(context, widgetOverrides));
    });
  }

  Stack _buildStack(BuildContext context, [List<Widget>? widgetOverrides]) {
    var theme = Theme.of(context);
    var actualWidgets = widgetOverrides ?? cachedLayers;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(color: theme.scaffoldBackgroundColor),
        ...actualWidgets!,
      ],
    );
  }

  Iterable<Widget> _buildLayers(BuildContext context) {
    return layers
        .whereNot((element) => element.logical)
        .mapIndexed((a, b) => _buildLayer(context, a, b));
  }

  Widget _buildLayer(BuildContext context, int i, PicassoLayer e) {
    var transform = transforms[i];
    var wrapped = e.buildCached(context, transform, this);
    if (selectedLayer == i && shadeSelectedLayout) {
      wrapped = Opacity(opacity: 0.5, child: wrapped);
    }
    if (e.rotatable || e.forceRotatable) {
      wrapped = Transform.rotate(angle: transform.rotation, child: wrapped);
    }
    if (e.tappable) {
      wrapped = GestureDetector(
        onTap: () {
          e.onTap(context, transforms[indexOf(e)], this);
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
  //endregion

  @override
  void scheduleRebuild() {
    Future.delayed(const Duration(microseconds: 1)).then((value) {
      setState(() {});
    });
  }

  @override
  void performRenderPass(Future Function() callback) {
    isRenderPass = true;
    renderPassCallback = callback;
    scheduleRebuild();
  }

  @override
  Future<ByteBuffer> getImage() {
    var ratio = widget.settings.width / canvasSize.width;
    var completer = Completer<ByteBuffer>();
    performRenderPass(() async {
      var image = await renderRepaintBoundary.toImage(pixelRatio: ratio);
      var pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      completer.complete(pngData!.buffer);
    });
    return completer.future;
  }

  @override
  Future<RenderOutput> getRenderOutput() {
    var ratio = widget.settings.width / canvasSize.width;
    var completer = Completer<RenderOutput>();
    performRenderPass(() async {
      var image = await renderRepaintBoundary.toImage(pixelRatio: ratio);
      var pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      completer.complete(RenderOutput(pngData!.buffer, annotatedRenderData));
    });
    return completer.future;
  }
}
