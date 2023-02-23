import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

mixin SingleSliderValue {
  double get value;

  set value(double value);
  void reset() {}
  void scheduleRebuild(PicassoCanvasState state);
}

void showSingleSliderDialog(
    BuildContext context, SingleSliderValue layer, PicassoEditorState state,
    {bool resettable = false}) {
  showModalBottomSheet(
      context: context,
      builder: (context) => _SingleSliderDialog(
            state: state,
            layer: layer,
            resettable: resettable,
          ));
}

// ignore: must_be_immutable
class _SingleSliderDialog extends StatefulWidget {
  final SingleSliderValue layer;
  final PicassoEditorState state;
  final bool resettable;

  const _SingleSliderDialog(
      {required this.state, required this.layer, required this.resettable});

  @override
  State<_SingleSliderDialog> createState() => _SingleSliderDialogState();
}

class _SingleSliderDialogState extends State<_SingleSliderDialog> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: _SingleSliderValueSlider(
                layer: widget.layer,
                editorState: widget.state,
              ),
            ),
          ),
          if (widget.resettable)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                  onPressed: () {
                    widget.layer.reset();
                    widget.layer.scheduleRebuild(widget.state.canvas);
                    setState(() {});
                  },
                  icon: const Icon(Icons.undo)),
            )
        ],
      ),
    );
  }
}

class _SingleSliderValueSlider extends StatefulWidget {
  final PicassoEditorState editorState;
  final SingleSliderValue layer;

  const _SingleSliderValueSlider(
      {Key? key, required this.layer, required this.editorState})
      : super(key: key);

  @override
  State<_SingleSliderValueSlider> createState() =>
      _SingleSliderValueSliderState();
}

class _SingleSliderValueSliderState extends State<_SingleSliderValueSlider> {
  @override
  Widget build(BuildContext context) {
    return Slider(
        value: widget.layer.value,
        min: 0.0,
        max: 1.0,
        onChanged: (val) {
          widget.layer.value = val;
          widget.layer.scheduleRebuild(widget.editorState.canvas);
          setState(() {});
        });
  }
}
