import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:picasso/picasso.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

@internal
const tau = 2 * pi;

/// Centers the [transform] of [layer] relative to [canvas].
TransformData makeCentered(
    Rect canvas, TransformData? transform, PicassoLayer layer) {
  transform ??= const TransformData(x: 0, y: 0, scale: 1, rotation: 0);
  var currentSize = layer.calculateSize(canvas.size, transform) ?? Size.zero;
  var transformData = transform.copyWith(
      x: (canvas.width / 2) - (currentSize.width / 2),
      y: (canvas.height / 2) - (currentSize.height / 2));
  return transformData;
}

/// Scales the [TransformData] of a [layer] to fit to a [ratio] of the [canvas],
/// while still covering the whole [layer] using [BoxFit.cover].
TransformData scaleToRatioCover(
    Rect canvas, TransformData? transform, PicassoLayer layer, double ratio) {
  transform ??= const TransformData(x: 0, y: 0, scale: 1, rotation: 0);
  var uniformSize =
      layer.calculateSize(canvas.size, transform.copyWith(scale: 1)) ??
          Size.zero;
  var fittedSize = applyBoxFit(BoxFit.cover, uniformSize, canvas.size);
  var scale = fittedSize.destination.width / fittedSize.source.width;
  return transform.copyWith(scale: scale * ratio);
}

/// Scales the [TransformData] of a [layer] to fit to a [ratio] of the [canvas],
/// while still containing the whole [layer] inside it using [BoxFit.contain].
TransformData scaleToRatioContain(
    Rect canvas, TransformData? transform, PicassoLayer layer, double ratio) {
  transform ??= const TransformData(x: 0, y: 0, scale: 1, rotation: 0);
  var uniformSize =
      layer.calculateSize(canvas.size, transform.copyWith(scale: 1)) ??
          Size.zero;
  var fittedSize = applyBoxFit(BoxFit.contain, uniformSize, canvas.size);
  var scale = fittedSize.destination.width / fittedSize.source.width;
  return transform.copyWith(scale: scale * ratio);
}

/// Creates a simple loading animation for use in images.
@internal
Widget tileImageLoadingBuilder(
    BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
  if (loadingProgress == null) return child;
  return Container(
    width: 128,
    height: 128,
    alignment: Alignment.center,
    child: CircularProgressIndicator(
      value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded /
              loadingProgress.expectedTotalBytes!
          : null,
    ),
  );
}

/// Load a [ui.Image] from an [ImageProvider].
Future<ui.Image> loadImageFromProvider(ImageProvider provider) async {
  Completer<ui.Image> completer = Completer<ui.Image>();
  provider
      .resolve(ImageConfiguration.empty)
      .addListener(ImageStreamListener((ImageInfo info, bool _) {
    completer.complete(info.image);
  }));
  return await completer.future;
}

/// Copied from https://github.com/brendan-duncan/image/blob/main/doc/flutter.md
Future<ui.Image> convertImageToFlutterUi(img.Image image) async {
  if (image.format != img.Format.uint8 || image.numChannels != 4) {
    final cmd = img.Command()
      ..image(image)
      ..convert(format: img.Format.uint8, numChannels: 4);
    final rgba8 = await cmd.getImageThread();
    if (rgba8 != null) {
      image = rgba8;
    }
  }

  ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

  ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
      height: image.height,
      width: image.width,
      pixelFormat: ui.PixelFormat.rgba8888);

  ui.Codec codec = await id.instantiateCodec(
      targetHeight: image.height, targetWidth: image.width);

  ui.FrameInfo fi = await codec.getNextFrame();
  ui.Image uiImage = fi.image;

  return uiImage;
}

Future<img.Image> convertFlutterUiToImage(ui.Image uiImage) async {
  final uiBytes = await uiImage.toByteData(format: ui.ImageByteFormat.png);
  return img.decodeImage(uiBytes!.buffer.asUint8List())!;
}
