import 'package:flutter/material.dart';
import 'package:picasso/src/editor.dart';

export 'tools/filter.dart';
export 'tools/image.dart';
export 'tools/stencil.dart';
export 'tools/sticker.dart';
export 'tools/text.dart';

/// Defines a tool or extension for a [PicassoEditor].
abstract class PicassoTool {
  /// Defines if the tool is visible in the toolbar of [PicassoEditor].
  final bool visible;

  const PicassoTool({this.visible = true});

  /// Returns the presentation data for this given tool.
  PicassoToolDisplay getDisplay(PicassoEditorState state);

  /// Initializes the tool for [state].
  void initialise(BuildContext context, PicassoEditorState state);

  /// Late-Initializes the tool for [state].
  void lateInitialise(BuildContext context, PicassoEditorState state) {}

  /// Invokes the tool for [state].
  /// Gets called when a user interacts with the [PicassoToolDisplay].
  void invoke(BuildContext context, PicassoEditorState state);
}

/// Visual presentation data for [PicassoTool]s.
class PicassoToolDisplay {
  final String name;
  final IconData icon;

  PicassoToolDisplay(this.name, this.icon);
}

class ExportTool extends PicassoTool {
  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay("Export", Icons.download);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {}

  @override
  void invoke(BuildContext context, PicassoEditorState state) async {
    var image = await state.canvas.getImage();
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    showDialog(
        context: context,
        builder: (context) => Container(
            color: Colors.white, child: Image.memory(image.asUint8List())));
  }
}
