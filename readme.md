# Godot CameraServer Quick Start

A quick start project for Godot 4
[CameraServer](https://docs.godotengine.org/en/stable/classes/class_cameraserver.html)
, uses minimal code possible to bring camera feeds onto the screen using a `TextureRect`.

To test, just clone this project and run it.

While a demo project exists: [godot-camerafeed-demo](https://github.com/shiena/godot-camerafeed-demo),
it serves as a full-fledged feature showcase.

The purpose of this project is to serve as a starting point, and the code itself documents
the exact steps to use `CameraServer` correctly.

Tested platforms: Android, Linux

# How to use

1. Copy `camera_texture_rect.gd` and `ycbcr_to_rgb.gdshader` to your project.

2. Edit the `ycbcr_to_rgb.gdshader` preload path inside `camera_texture_rect.gd`. (If path changes)

3. Create a `TextureRect` in your scene, attach the script `camera_texture_rect.gd` to it.

4. Configure the export variables of the script, see details in the code comments. (You can also leave them as default)

5. Run the project

# Notes

*
