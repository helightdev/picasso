import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:duffer/duffer.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:picasso/picasso.dart';
import 'package:http/http.dart' as http;

abstract class PicassoLayerSerializer {

  String serialName;

  PicassoLayerSerializer(this.serialName);

  bool check(PicassoLayer layer);
  FutureOr<void> serialize(PicassoLayer layer, ByteBuf buf, PicassoCanvasState state);
  FutureOr<PicassoLayer> deserialize(ByteBuf buf, PicassoCanvasState state, PicassoEditorState? editorState);

}

Future<Uint8List> getImageProviderBytes(ImageProvider provider) async {
  if (provider is MemoryImage) {
    return provider.bytes;
  } else if (provider is NetworkImage) {
    var response = await http.get(Uri.parse(provider.url));
    return response.bodyBytes;
  } else if (provider is AssetImage) {
    AssetBundleImageKey key = await provider.obtainKey(ImageConfiguration());
    var data = await key.bundle.load(key.name);
    var bytes = data.buffer.asUint8List();
    return bytes;
  } else {
    var img = await loadImageFromProvider(provider);
    var data = await img.toByteData(format: ImageByteFormat.png);
    var bytes = data!.buffer.asUint8List();
    return bytes;
  }
}

extension PicassoSerialization on ByteBuf {

  static final Logger _logger = Logger("PicassoSerilizationExtension");

  SizedImage readSizedImage() {
    var dimensions = readSize();
    var image = readImageProvider();
    return SizedImage(image, dimensions);
  }

  Future writeSizedImage(SizedImage image) async {
    writeSize(image.dimensions);
    await writeImageProvider(image.image);
  }

  ImageProvider readImageProvider() {
    var id = readByte();
    switch (id) {
      case 0x01:
        var len = readInt64();
        return MemoryImage(readBytes(len));
      case 0x02:
        return NetworkImage(readLPString());
      default:
        throw Exception("Unknown image provider type $id");
    }
  }

  Future writeImageProvider(ImageProvider provider) async {
    if (provider is MemoryImage) {
      writeByte(0x01);
      writeInt64(provider.bytes.length);
      writeBytes(provider.bytes);
    } else if (provider is NetworkImage) {
      writeByte(0x02);
      writeLPString(provider.url);
    } else if (provider is AssetImage) {
      AssetBundleImageKey key = await provider.obtainKey(ImageConfiguration());
      var data = await key.bundle.load(key.name);
      var bytes = data.buffer.asUint8List();
      writeByte(0x01);
      writeInt64(bytes.length);
      writeBytes(bytes);
    } else {
      var img = await loadImageFromProvider(provider);
      var data = await img.toByteData(format: ImageByteFormat.png);
      var bytes = data!.buffer.asUint8List();
      writeByte(0x01);
      writeInt64(bytes.length);
      writeBytes(bytes);
    }
  }

  TransformData readTransformData() {
    var x = readFloat64();
    var y = readFloat64();
    var scale = readFloat32();
    var rotation = readFloat32();
    return TransformData(x: x, y: y, scale: scale, rotation: rotation);
  }

  void writeTransformData(TransformData data) {
    writeFloat64(data.x);
    writeFloat64(data.y);
    writeFloat32(data.scale);
    writeFloat32(data.rotation);
  }

  TextStyle readTextStyle() {
    try {
      var buf = readLPBuffer();
      double? fontSize = buf.readNullable(() => buf.readFloat32());
      Color? color = buf.readNullable(() => buf.readColor());
      FontWeight? fontWeight = buf.readNullable(() {
            var fontWeightValue = buf.readInt32();
            return FontWeight.values.firstWhere((element) =>
              element.value == fontWeightValue);
          });
      List<Shadow>? shadows = buf.readNullable(() {
            var len = buf.readByte();
            return List.generate(len, (index) => buf.readShadow());
          });
      String? fontFamily = buf.readNullable(() => buf.readLPString());
      Color? backgroundColor = buf.readNullable(() => buf.readColor());
      FontStyle? fontStyle = buf.readNullable(() {
            var name = buf.readLPString();
            return FontStyle.values.firstWhere((element) => element.name == name);
          });
      TextDecoration? decoration = buf.readNullable(() {
            var lineThrough = buf.readBool();
            var overline = buf.readBool();
            var underline = buf.readBool();
            return TextDecoration.combine([
              if (lineThrough) TextDecoration.lineThrough,
              if (overline) TextDecoration.overline,
              if (underline) TextDecoration.underline
            ]);
          });
      TextDecorationStyle? decorationStyle = buf.readNullable(() {
            var name = buf.readLPString();
            return TextDecorationStyle.values.firstWhere((element) => element.name == name);
          });
      double? decorationThickness = buf.readNullable(() => buf.readFloat32());
      Color? decorationColor = buf.readNullable(() => buf.readColor());
      double? letterSpacing = buf.readNullable(() => buf.readFloat32());
      double? wordSpacing = buf.readNullable(() => buf.readFloat32());
      double? height = buf.readNullable(() => buf.readFloat32());
      TextLeadingDistribution? leadingDistribution = buf.readNullable(() {
            var name = buf.readLPString();
            return TextLeadingDistribution.values.firstWhere((element) => element.name == name);
          });
      TextOverflow? overflow = buf.readNullable(() {
            var name = buf.readLPString();
            return TextOverflow.values.firstWhere((element) => element.name == name);
          });
      TextBaseline? textBaseline = buf.readNullable(() {
            var name = buf.readLPString();
            return TextBaseline.values.firstWhere((element) => element.name == name);
          });
      bool inherit = buf.readBool();

      return TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            shadows: shadows,
            fontFamily: fontFamily,
            backgroundColor: backgroundColor,
            fontStyle: fontStyle,
            decoration: decoration,
            decorationStyle: decorationStyle,
            decorationThickness: decorationThickness,
            decorationColor: decorationColor,
            letterSpacing: letterSpacing,
            wordSpacing: wordSpacing,
            height: height,
            leadingDistribution: leadingDistribution,
            overflow: overflow,
            textBaseline: textBaseline,
            inherit: inherit,
          );
    } catch (e,st) {
      _logger.severe("Encountered exception while trying to read TextStyle", e, st);
      return TextStyle();
    }
  }

  void writeTextStyle(TextStyle style) {
    // Use inside guarded buffer improving error recoverability.
    var buf = Unpooled.buffer();
    buf.writeNullable(style.fontSize, (p0) => buf.writeFloat32(p0));
    buf.writeNullable(style.color, (p0) => buf.writeColor(p0));
    buf.writeNullable(style.fontWeight, (p0) => buf.writeInt32(p0.value));
    buf.writeNullable(style.shadows, (p0) {
      buf.writeByte(style.shadows!.length);
      for (var value in style.shadows!) {
        buf.writeShadow(value);
      }
    });
    buf.writeNullable(style.fontFamily, (p0) => buf.writeLPString(p0));
    buf.writeNullable(style.backgroundColor, (p0) => buf.writeColor(p0));
    buf.writeNullable(style.fontStyle, (p0) => buf.writeLPString(p0.name));
    buf.writeNullable(style.decoration, (p0) {
      buf.writeBool(p0.contains(TextDecoration.lineThrough));
      buf.writeBool(p0.contains(TextDecoration.overline));
      buf.writeBool(p0.contains(TextDecoration.underline));
    });
    buf.writeNullable(style.decorationStyle, (p0) => buf.writeLPString(p0.name));
    buf.writeNullable(style.decorationThickness, (p0) => buf.writeFloat32(p0));
    buf.writeNullable(style.decorationColor, (p0) => buf.writeColor(p0));
    buf.writeNullable(style.letterSpacing, (p0) => buf.writeFloat32(p0));
    buf.writeNullable(style.wordSpacing, (p0) => buf.writeFloat32(p0));
    buf.writeNullable(style.height, (p0) => buf.writeFloat32(p0));
    buf.writeNullable(style.leadingDistribution, (p0) => buf.writeLPString(p0.name));
    buf.writeNullable(style.overflow, (p0) => buf.writeLPString(p0.name));
    buf.writeNullable(style.textBaseline, (p0) => buf.writeLPString(p0.name));
    buf.writeBool(style.inherit);
    writeLPBuffer(buf);
  }

  Shadow readShadow() {
    var color = readColor();
    var blurRadius = readFloat32();
    var offset = readOffset();
    return Shadow(
        color: color,
        blurRadius: blurRadius,
        offset: offset
    );
  }

  void writeShadow(Shadow shadow) {
    writeColor(shadow.color);
    writeFloat32(shadow.blurRadius);
    writeOffset(shadow.offset);
  }

  void writeOffset(Offset offset) {
    writeFloat32(offset.dx);
    writeFloat32(offset.dy);
  }

  Offset readOffset() {
    return Offset(readFloat32(), readFloat32());
  }

  void writeSize(Size size) {
    writeFloat32(size.width);
    writeFloat32(size.height);
  }

  Size readSize() {
    return Size(readFloat32(), readFloat32());
  }

  void writeColor(Color color) {
    writeInt32(color.value);
  }

  Color readColor() {
    return Color(readInt32());
  }

}