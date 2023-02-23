import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:picasso/picasso.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

mixin RawImageTarget on PicassoLayer {
  ui.Image get source;
  set source(ui.Image image);

  ui.Image get output;
  set output(ui.Image image);

  img.Image? libSourceImage;

  List<RawImageTransformer> transformers = [];

  Future<img.Image> getLibSourceImage() async {
    if (libSourceImage == null) {
      var image = await convertFlutterUiToImage(source);
      libSourceImage = image;
      return image;
    }
    return libSourceImage!;
  }

  void addTransformer(RawImageTransformer transformer) {
    transformers.add(transformer);
  }

  bool _isRenderLocked = false;
  final List<Completer> _waitingRenderSubscribers = [];

  Future<void> render(PicassoCanvasState state,
      [List<Completer> subscribers = const []]) async {
    var stopwatch = Stopwatch();
    if (kDebugMode) stopwatch.start();
    if (_isRenderLocked) {
      var completer = Completer();
      _waitingRenderSubscribers.add(completer);
      await completer.future;
      return;
    }
    state.showLoading();
    _isRenderLocked = true;
    var image = await getLibSourceImage();
    for (var value in transformers) {
      image = await value.apply(image, state);
    }
    output = await convertImageToFlutterUi(image);
    setDirty(state);
    state.hideLoading();
    _isRenderLocked = false;
    for (var element in subscribers) {
      element.complete(null);
    }
    if (_waitingRenderSubscribers.isNotEmpty) {
      render(state, _waitingRenderSubscribers.toList());
      _waitingRenderSubscribers.clear();
    }
    if (kDebugMode) {
      stopwatch.stop();
      print("Raw Image Processing took ${stopwatch.elapsedMilliseconds}ms");
    }
  }
}

abstract class RawImageTransformer {
  Future<img.Image> apply(img.Image image, PicassoCanvasState state);
}
