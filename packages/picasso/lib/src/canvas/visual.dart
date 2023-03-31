import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

mixin CanvasVisualsMixin on PicassoCanvasState {
  bool isObscuring = false;
  bool isLoading = false;
  bool _showDeleteIcon = false;
  @override
  Offset deleteIconOffset = Offset.zero;

  late Animation<double> _trashAnimation;
  late AnimationController _trashAnimationController;

  @override
  set showDeleteIcon(bool value) {
    if (value == true) {
      if (!_showDeleteIcon) {
        _trashAnimationController.forward(from: 0);
      }
      _showDeleteIcon = true;
    } else {
      _showDeleteIcon = false;
      _trashAnimationController.value = 0;
    }
  }

  @override
  void initState() {
    _trashAnimationController = AnimationController(
        vsync: this as TickerProvider,
        duration: const Duration(milliseconds: 250));
    _trashAnimation =
        _trashAnimationController.drive(Tween(begin: 64.0, end: 0.0));
    _trashAnimationController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  List<Widget> buildOverlays(BuildContext context) {
    return [
      if (_showDeleteIcon) _buildDeleteIcon(),
      if (isLoading)
        const Center(
          child: CircularProgressIndicator(),
        )
    ];
  }

  Positioned _buildDeleteIcon() => Positioned.fromRect(
      rect: Rect.fromCircle(
          center: deleteIconOffset.translate(0, _trashAnimation.value),
          radius: 32),
      child: const Icon(Icons.delete, size: 32, color: Colors.white));

  @override
  void hideLoading() {
    isLoading = false;
    setState(() {});
  }

  @override
  void showLoading() {
    isLoading = true;
    setState(() {});
  }
}
