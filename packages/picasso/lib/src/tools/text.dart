import 'dart:async';

import 'package:collection/collection.dart';
import 'package:duffer/duffer.dart';
import 'package:duffer/src/bytebuf_base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'package:picasso/src/persistence/serializable.dart';

class TextTool extends PicassoTool {
  final String? name;
  final IconData icon;
  final TextStyle? style;

  const TextTool(
      {this.name,
      this.icon = Icons.text_fields,
      this.style = const TextStyle(
          color: Colors.white, shadows: TextToolUtils.impactOutline)});

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.textName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {}

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    state.widget.dialogFactory.promptText(context, style: style).then((value) {
      if (value.replaceAll(" ", "") == "") return;
      var layer = TextLayer(value, style, this, true);
      var transform = makeCentered(state.canvas.rect,
          const TransformData(x: 0, y: 0, scale: 2, rotation: 0), layer);
      state.canvas.addLayer(layer, transform);
    });
  }

  Future<String> requestText(BuildContext context, [String? initialText]) {
    var completer = Completer<String>();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: TextField(
              onSubmitted: (string) {
                completer.complete(string);
                Navigator.pop(context);
              },
              autofocus: true,
              controller: TextEditingController(text: initialText),
              decoration: const InputDecoration(prefixText: "  "),
              style: style,
            ),
          );
        },
        isScrollControlled: true);
    return completer.future;
  }
}

class TextLayer extends PicassoLayer {
  final TextTool? tool;
  final bool editable;

  TextStyle? style;
  String text;

  TextLayer(this.text, this.style, this.tool, this.editable) : super() {
    flags = LayerFlags.presetDefault ^ (editable ? 0 : LayerFlags.tappable);
    associatedTool = tool;
  }

  @override
  Size? calculateSize(Size canvas, TransformData data) =>
      TextToolUtils.calculateSize(text, style, data);

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    name = "Text \"$text\"";
    return Text(
      text,
      style: style,
      textScaleFactor: data.scale,
      textAlign: TextAlign.center,
    );
  }

  @override
  void onTap(BuildContext context, TransformData data,
      PicassoCanvasState state) async {
    if (tool == null) return;
    var newText = await context.findAncestorStateOfType<PicassoEditorState>()!
        .widget.dialogFactory.promptText(context, style: style, initialValue: text);
    text = newText;
    setDirty(state);
  }
}

class TextLayerSerializer extends PicassoLayerSerializer {
  TextLayerSerializer() : super("picasso:text");

  @override
  bool check(PicassoLayer layer) {
    return layer is TextLayer;
  }

  @override
  PicassoLayer deserialize(ByteBuf buf, PicassoCanvasState state, PicassoEditorState? editorState) {
    var style = buf.readTextStyle();
    var text = buf.readLPString();
    return TextLayer(text, style, editorState?.tools.whereType<TextTool>().firstOrNull, false);
  }

  @override
  void serialize(PicassoLayer layer, ByteBuf buf, PicassoCanvasState state) {
    var textLayer = layer as TextLayer;
    buf.writeTextStyle(textLayer.style ?? const TextStyle());
    buf.writeLPString(textLayer.text);
  }
}

class TextToolUtils {
  TextToolUtils._();

  static const List<Shadow> impactOutline = [
    Shadow(offset: Offset(-1.5, -1.5), color: Colors.black54, blurRadius: 5),
    Shadow(offset: Offset(1.5, -1.5), color: Colors.black54, blurRadius: 5),
    Shadow(offset: Offset(1.5, 1.5), color: Colors.black54, blurRadius: 5),
    Shadow(offset: Offset(-1.5, 1.5), color: Colors.black54, blurRadius: 5),
  ];

  static List<Shadow> getBorder(
          {Color color = Colors.black, double width = 1.5, double blur = 0}) =>
      [
        Shadow(offset: Offset(-width, -width), color: color, blurRadius: blur),
        Shadow(offset: Offset(width, -width), color: color, blurRadius: blur),
        Shadow(offset: Offset(width, width), color: color, blurRadius: blur),
        Shadow(offset: Offset(-width, width), color: color, blurRadius: blur),
      ];

  static Size calculateSize(String text, TextStyle? style, TransformData data) {
    var painter = TextPainter(
        text: TextSpan(text: text, style: style), textScaleFactor: data.scale);
    painter.textDirection = TextDirection.ltr;
    painter.layout(minWidth: 0, maxWidth: double.infinity);
    return Size(painter.width, painter.height);
  }
}
