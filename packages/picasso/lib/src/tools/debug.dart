import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';
import 'package:picasso/src/canvas/readonly.dart';

class PreviewTool extends PicassoTool {
  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) {
    return PicassoToolDisplay("Preview", Icons.preview);
  }

  @override
  void initialise(BuildContext context, PicassoEditorState state) {

  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) async {
    var buf = await PicassoSaveSystem.instance.save(state.canvas);
    var saveData = PicassoSaveSystem.instance.load(buf);
    if (context.mounted) {
      showDialog(context: context, builder: (context) => Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: SizedBox(
          width: 512,
          height: 256,
          child: PicassoView(data: saveData, bindings: state.canvas.bindings,),
        ),
      ),
    ));
    }
  }
}

class ReloadTool extends PicassoTool {
  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) {
    return PicassoToolDisplay("Save & Load", Icons.restart_alt);
  }

  @override
  void initialise(BuildContext context, PicassoEditorState state) {

  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) async {
    var buf = await PicassoSaveSystem.instance.save(state.canvas);
    var saveData = PicassoSaveSystem.instance.load(buf);
    if (context.mounted) {
      showPicassoEditorDialogTools(context: context, tools: state.tools, saveData: saveData, bindings: state.widget.bindings, settings: state.widget.settings, callback: (output) {});
    }
  }
}

class ExportTool extends PicassoTool {
  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay("Export", Icons.download);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {}

  @override
  void invoke(BuildContext context, PicassoEditorState state) async {
    var output = await state.canvas.getRenderOutput(imageOnly: true);
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    showDialog(
        context: context,
        builder: (context) => Container(
            color: Colors.white, child: Image.memory(output.image.array())));
  }
}
