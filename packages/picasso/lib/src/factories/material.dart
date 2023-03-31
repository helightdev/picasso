import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:picasso/picasso.dart';

class BottomSheetEditorDialogFactory extends EditorDialogFactory {
  const BottomSheetEditorDialogFactory();

  @override
  Future<String> promptText(BuildContext context,
      {String? prefix, String? initialValue, TextStyle? style}) async {
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
              controller: TextEditingController(text: initialValue),
              decoration: InputDecoration(
                  prefix: SizedBox(
                width: 16,
                child: Text(prefix ?? ""),
              )),
              style: style,
            ),
          );
        },
        isScrollControlled: true);
    return completer.future;
  }

  @override
  void showDialog(BuildContext context, WidgetBuilder builder) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Builder(builder: builder),
          );
        },
        isScrollControlled: true);
  }
}

class MaterialDialogEditorDialogFactory extends EditorDialogFactory {
  const MaterialDialogEditorDialogFactory();

  @override
  Future<String> promptText(BuildContext context,
      {String? prefix, String? initialValue, TextStyle? style}) async {
    var themeData = Theme.of(context);
    var completer = Completer<String>();
    mat.showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            elevation: 2.5,
            child: TextField(
              onSubmitted: (string) {
                completer.complete(string);
                Navigator.pop(context);
              },
              autofocus: true,
              controller: TextEditingController(text: initialValue),
              decoration: InputDecoration(
                  prefix: SizedBox(
                width: 16,
                child: Text(prefix ?? ""),
              )),
              style: style,
            ),
          );
        });
    return completer.future;
  }

  @override
  void showDialog(BuildContext context, WidgetBuilder builder) {
    mat.showDialog(
        context: context,
        builder: (context) {
          return Dialog(elevation: 2.5, child: Builder(builder: builder));
        });
  }
}
