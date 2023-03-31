// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:picasso/picasso.dart';
import 'dart:ui' as ui;

mixin BakeTarget on PicassoTool {
  void onBake(PicassoEditorState state, ui.Image image);
}

extension BakeExtension on PicassoEditorState {
  /// "Bakes" the current editor state into an image and then fully resets the
  /// canvas and reinitializes all tools on this canvas again. Tools which
  /// possess the [BakeTarget] mixin will receive a callback containing the
  /// new image data after all tools have been initialized.
  Future bake(BuildContext context) async {
    var bakeTargets = tools.whereType<BakeTarget>();
    var imageBytes = await canvas.getImage();
    var imageCompleter = Completer<ui.Image>();
    ui.decodeImageFromList(imageBytes.asUint8List(), (result) {
      imageCompleter.complete(result);
    });
    var image = await imageCompleter.future;
    canvas.layers.clear();
    canvas.transforms.clear();
    canvas.selectedLayer = null;
    canvas.isDragging = false;
    canvas.shadeSelectedLayout = false;
    canvas.showDeleteIcon = false;
    canvas.rebuildAllLayers(); // Schedule full rebuild.
    if (!context.mounted) throw Exception();
    for (var tool in tools) {
      tool.initialise(context, this);
    }
    for (var tool in tools) {
      tool.lateInitialise(context, this);
    }
    for (var element in bakeTargets) {
      element.onBake(this, image);
    }
    canvas.scheduleRebuild(); // Rebuild now even if not already scheduled.
  }
}
