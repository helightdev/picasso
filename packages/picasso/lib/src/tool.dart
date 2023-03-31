import 'package:flutter/material.dart';
import 'package:picasso/picasso.dart';

export 'tools/debug.dart';
export 'tools/filter.dart';
export 'tools/gif.dart';
export 'tools/image.dart';
export 'tools/layers.dart';
export 'tools/raw.dart';
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

  Iterable<PopupMenuEntry<VoidCallback>> getLayerOptions(BuildContext context, PicassoEditorState state, PicassoLayer layer) => [];
}

/// Visual presentation data for [PicassoTool]s.
class PicassoToolDisplay {
  final String name;
  final IconData icon;

  PicassoToolDisplay(this.name, this.icon);
}

/// Represents an [ImageProvider] tagged with the image [Size].
class SizedImage {
  final ImageProvider image;
  final Size dimensions;

  const SizedImage(this.image, this.dimensions);
}