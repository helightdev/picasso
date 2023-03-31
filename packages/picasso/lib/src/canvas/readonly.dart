import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

class PicassoView extends StatelessWidget {
  final CanvasSaveData data;
  final Map<String, dynamic> bindings;

  const PicassoView({Key? key, required this.data, this.bindings = const {}}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context,constraints) {
        var fitted = applyBoxFit(BoxFit.cover, data.targetSize, constraints.biggest);
        var scale = fitted.destination.width / fitted.source.width;
        var width = data.targetSize.width * scale;
        var height = data.targetSize.height * scale;
        return Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          children: [
            Positioned(
              width: width,
              height: height,
              child: PicassoCanvas(settings: CanvasSettings(width: data.targetSize.width, height: data.targetSize.height, readonly: true), bindings: bindings, saveData: data,),
            ),
          ],
        );
      }
    );
  }
}
