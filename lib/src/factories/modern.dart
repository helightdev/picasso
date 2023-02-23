import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

class ModernFloatingEditorContainerFactory extends EditorContainerFactory {
  const ModernFloatingEditorContainerFactory();

  @override
  Widget get(BuildContext context, PicassoEditorState state,
      BoxConstraints constraints) {
    var toolbarItems = state.buildToolbarIcons(context: context, dense: true);
    var canvas = state.buildCanvas();

    var canvasConstraints = constraints;
    var bottomWidgetSize = Size.zero;
    if (state.hasBottomWidget) {
      bottomWidgetSize = state.getBottomWidgetSize(context);
      canvasConstraints = canvasConstraints.copyWith(
          maxHeight: canvasConstraints.maxHeight - bottomWidgetSize.height);
    }

    return Stack(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: canvasConstraints.maxWidth,
              maxHeight: canvasConstraints.maxHeight),
          child: Align(alignment: Alignment.topCenter, child: canvas),
        ),
        Positioned(
            top: 8,
            right: 16,
            width: 32,
            height: state.optionalCanvas == null
                ? constraints.maxHeight
                : state.canvas.canvasSize.height,
            child: ScrollConfiguration(
              behavior: _ColumnRowScrollBehaviour().copyWith(scrollbars: false),
              child: ListView(
                  key: const ValueKey(#ModernFloatingToolbar),
                  children: toolbarItems),
            )),
        if (state.hasBottomWidget)
          Positioned(
              bottom: 0,
              height: state.optionalCanvas == null
                  ? constraints.maxHeight
                  : constraints.maxHeight - state.canvas.canvasSize.height,
              child: Column(children: [
                const Spacer(),
                SizedBox(
                  width: constraints.maxWidth,
                  height: bottomWidgetSize.height,
                  child: state.buildBottomWidget(context),
                )
              ])),
      ],
    );
  }
}

class ModernColumnEditorContainerFactory extends EditorContainerFactory {
  const ModernColumnEditorContainerFactory();

  @override
  Widget get(BuildContext context, PicassoEditorState state,
      BoxConstraints constraints) {
    var toolbarItems = state.buildToolbarIcons(context: context, dense: false);
    var canvas = state.buildCanvas();
    var toolbarItemSize =
        state.widget.displayWidgetFactory.getSize(context, false);

    var canvasConstraints = constraints.copyWith(
        maxHeight: constraints.maxHeight - toolbarItemSize.height - 4);

    var bottomWidgetSize = Size.zero;
    if (state.hasBottomWidget) {
      bottomWidgetSize = state.getBottomWidgetSize(context);
      canvasConstraints = canvasConstraints.copyWith(
          maxHeight: canvasConstraints.maxHeight - bottomWidgetSize.height);
    }

    double toolbarPadding = 0;
    var occupied = toolbarItemSize.width * toolbarItems.length;
    if (occupied < constraints.maxWidth) {
      var unused = constraints.maxWidth - occupied;
      toolbarPadding = unused / 2;
    }

    toolbarItems = [
      SizedBox(
        width: toolbarPadding,
        height: 0,
      ),
      ...toolbarItems
    ];

    return Stack(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: canvasConstraints.maxWidth,
              maxHeight: canvasConstraints.maxHeight),
          child: Align(alignment: Alignment.topCenter, child: canvas),
        ),
        Positioned(
            bottom: 0,
            height: state.optionalCanvas == null
                ? constraints.maxHeight
                : constraints.maxHeight - state.canvas.canvasSize.height,
            child: Column(children: [
              const Spacer(),
              SizedBox(
                  width: constraints.maxWidth,
                  height: toolbarItemSize.height,
                  child: ScrollConfiguration(
                      behavior: _ColumnRowScrollBehaviour()
                          .copyWith(scrollbars: false),
                      child: ListView(
                          key: const ValueKey(#ModernColumnToolbar),
                          scrollDirection: Axis.horizontal,
                          children: toolbarItems))),
              const Spacer(),
              if (state.hasBottomWidget)
                SizedBox(
                  width: constraints.maxWidth,
                  height: bottomWidgetSize.height,
                  child: state.buildBottomWidget(context),
                )
            ])),
      ],
    );
  }
}

class ModernToolDisplayWidgetFactory extends ToolDisplayWidgetFactory {
  final TextStyle? textStyle;
  final bool increasedSize;

  const ModernToolDisplayWidgetFactory(
      {this.increasedSize = false, this.textStyle});

  @override
  Widget get(BuildContext context, PicassoToolDisplay display,
      void Function() callback, bool dense) {
    var theme = Theme.of(context);
    if (dense) {
      return IconButton(
          onPressed: callback,
          icon: Icon(
            display.icon,
            color: Colors.white,
            shadows: const [
              BoxShadow(
                  color: Colors.black54,
                  spreadRadius: 6,
                  blurRadius: 6,
                  offset: Offset(1, 1))
            ],
            size: 24,
          ));
    } else {
      return SizedBox(
        width: 64 + 24,
        child: InkWell(
            onTap: callback,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  display.icon,
                  color: theme.colorScheme.onBackground,
                  size: increasedSize ? 48 : 32,
                ),
                Text(
                  display.name,
                  style: textStyle ??
                      (theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onBackground)),
                )
              ],
            )),
      );
    }
  }

  @override
  Size getSize(BuildContext context, bool dense) {
    return dense ? const Size(24, 24) : Size(64 + 24, increasedSize ? 128 : 64);
  }
}

class _ColumnRowScrollBehaviour extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

void _noAction() {}

class ElevatedButtonBottomWidgetFactory extends EditorBottomWidgetFactory {
  final Widget child;
  final VoidCallback onTap;
  final ButtonStyle? style;

  const ElevatedButtonBottomWidgetFactory(
      {required this.child, this.onTap = _noAction, this.style});

  factory ElevatedButtonBottomWidgetFactory.done(
      {VoidCallback onTap = _noAction, ButtonStyle? style}) {
    return ElevatedButtonBottomWidgetFactory(child: Builder(builder: (context) {
      var editorState = context.findAncestorStateOfType<PicassoEditorState>()!;
      return Text(editorState.translations.continueButton);
    }));
  }

  factory ElevatedButtonBottomWidgetFactory.$continue(
      {VoidCallback onTap = _noAction, ButtonStyle? style}) {
    return ElevatedButtonBottomWidgetFactory(child: Builder(builder: (context) {
      var editorState = context.findAncestorStateOfType<PicassoEditorState>()!;
      return Text(editorState.translations.continueButton);
    }));
  }

  @override
  Widget get(BuildContext context, PicassoEditorState state) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: style,
          child: child,
        ),
      ),
    );
  }

  @override
  Size getSize(BuildContext context, PicassoEditorState state) {
    return const Size(double.infinity, 64);
  }
}
