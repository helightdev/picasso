import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

class PicassoEditor extends StatefulWidget {
  final CanvasSettings settings;
  final List<PicassoTool> tools;
  final ToolDisplayWidgetFactory displayWidgetFactory;
  final EditorContainerFactory containerFactory;
  final EditorBottomWidgetFactory? bottomWidgetFactory;

  const PicassoEditor(
      {super.key,
      required this.settings,
      required this.tools,
      this.displayWidgetFactory = const ModernToolDisplayWidgetFactory(),
      this.containerFactory = const ModernColumnEditorContainerFactory(),
      this.bottomWidgetFactory})
      : super();

  @override
  State<PicassoEditor> createState() => _PicassoEditorState();
}

class EditorSettings {
  const EditorSettings();
}

abstract class PicassoEditorState extends State<PicassoEditor> {
  /// Builds the [PicassoCanvas] widget for this [PicassoEditor].
  PicassoCanvas buildCanvas();

  /// Builds the toolbar icons of this [PicassoEditor].
  List<Widget> buildToolbarIcons(
      {required BuildContext context, bool dense = false});

  /// Builds the bottom widget for this [PicassoEditor].
  Widget buildBottomWidget(BuildContext context);

  /// Returns the size of this [PicassoEditor]s bottom widget.
  Size getBottomWidgetSize(BuildContext context);

  /// Returns a cached [PicassoTranslations] instance.
  PicassoTranslations get translations;

  /// Returns if this [PicassoEditor] has bottom widget.
  bool get hasBottomWidget;

  /// Returns all tools currently present in this [PicassoEditor].
  List<PicassoTool> get tools;

  /// Returns the current canvas state and null if the canvas has not yet
  /// been initialized.
  PicassoCanvasState? get optionalCanvas;

  /// Returns the render object associated with this [PicassoEditor].
  RenderObject get editorRenderObject;

  /// Returns the current canvas state and throws an exception if the canvas
  /// is not yet initialized.
  PicassoCanvasState get canvas => optionalCanvas!;

  /// Returns all [PicassoTool]s which are accessible in the toolbar.
  List<PicassoTool> get visibleTools =>
      tools.where((element) => element.visible).toList();
}

class _PicassoEditorState extends PicassoEditorState {
  GlobalKey<PicassoCanvasState> canvasKey = GlobalKey();
  GlobalKey containerKey = GlobalKey();

  List<Widget>? toolInstances;
  BoxConstraints lastConstraints = BoxConstraints.loose(Size.zero);

  @override
  List<PicassoTool> get tools => widget.tools;
  @override
  PicassoCanvasState? optionalCanvas;

  @override
  RenderObject get editorRenderObject =>
      containerKey.currentContext!.findRenderObject()!;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (translationsCache == null) {
      try {
        translationsCache = PicassoTranslations.of(context);
      } catch (_) {
        // Get fallback locale
        translationsCache = lookupPicassoTranslations(const Locale("en"));
      }
    }
    var theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          lastConstraints = constraints;
          return widget.containerFactory.get(context, this, constraints);
        }),
      ),
    );
  }

  void initialise(BuildContext context) {
    for (var tool in tools) {
      tool.initialise(context, this);
    }
    for (var tool in tools) {
      tool.lateInitialise(context, this);
    }

    toolInstances = visibleTools
        .map((e) => IconButton(
            onPressed: () {
              e.invoke(context, this);
            },
            icon: Icon(e.getDisplay(this).icon)))
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

  @override
  PicassoCanvas buildCanvas() {
    return PicassoCanvas(
        settings: widget.settings,
        key: canvasKey,
        callback: (context, canvas) {
          optionalCanvas = canvas;
          initialise(context);
        });
  }

  @override
  List<Widget> buildToolbarIcons(
      {required BuildContext context, bool dense = false}) {
    return visibleTools
        .map((e) =>
            widget.displayWidgetFactory.get(context, e.getDisplay(this), () {
              e.invoke(context, this);
            }, dense))
        .toList();
  }

  @override
  Widget buildBottomWidget(BuildContext context) {
    return widget.bottomWidgetFactory!.get(context, this);
  }

  @override
  Size getBottomWidgetSize(BuildContext context) {
    return widget.bottomWidgetFactory!.getSize(context, this);
  }

  @override
  bool get hasBottomWidget => widget.bottomWidgetFactory != null;

  PicassoTranslations? translationsCache;

  @override
  PicassoTranslations get translations => translationsCache!;
}
