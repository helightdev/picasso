# Picasso

A modular cross-platform image editor package for flutter. It utilizes flutter rendering engine
by representing layers as a widget stack which is then rendered using RepaintBoundaries. It also
allows for direct modification of the image using the image package.

## Features

* **Modular** and easily extendable Editor Frontend
* Mobile friendly editing using **gestures** (**Move, Scale, Rotate**)
* Rotation and position **snapping** with haptic feedback
* Optional layer deletion using gestures

### Included Tools

* BackgroundImage  
  Options for modifying the image:
    * 90° left/right rotation
    * Mirror Image
    * Bake output into image
* Filter: Widget based general purpose selectable filters.  
  Default support for:
    * Single Tone
    * Linear Gradients
* Stencil: Simple non-interactive selectable overlays
* Sticker: Images than can be placed and moved on the canvas
* Text : General text input

## Video

Picasso partially supports gifs via GifTool and GifLayer.

To use any other kind of video with picasso, you have to encode it as a gif to work.
You can achieve this using a custom backend or inside the flutter app
using [flutter_video_compress](https://pub.dev/packages/flutter_video_compress)
or other ffmpeg bindings like [ffmpeg_kit_flutter](https://pub.dev/packages/ffmpeg_kit_flutter).
If you happen to find a cross platform solution for this, let me know and I'll update this section.

## Getting started

For example usage please refer to the example project.
A more detailed getting started guide is being currently worked on.
