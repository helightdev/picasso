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


## Getting started

For example usage please refer to the example project.
A more detailed getting started guide is being currently worked on.
