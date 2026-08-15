# Godot CameraServer Quick Start

Tested platforms: **Android, Linux**

Tested Godot version: **4.7.1** (You can downgrade to versions where `CameraServer` is still supported)

A quick start project for Godot 4
[CameraServer](https://docs.godotengine.org/en/stable/classes/class_cameraserver.html)
, uses minimal code possible to bring camera feeds onto the screen using a `TextureRect`.

Code is inside `godot_project/`, to test, clone this project and run it.

While a demo project exists: [godot-camerafeed-demo](https://github.com/shiena/godot-camerafeed-demo),
it serves as a full-fledged feature showcase.

The purpose of this project is to serve as a starting point, and the code itself documents
the exact steps to use `CameraServer` correctly.

# How to use

1. Copy `camera_texture_rect.gd` and `ycbcr_to_rgb.gdshader` to your project.

2. Update the `ycbcr_to_rgb.gdshader` preload path inside `camera_texture_rect.gd`. (If it changes)

3. Create a `TextureRect` node in your scene, attach the script `camera_texture_rect.gd` to it.

4. Configure the export variables of the script, see details in the code comments. (Or use default)

5. Run the project

# Sidenote for AR devs

If you are trying `ARKit` or `ARCore` integration, using `CameraServer` is the wrong route,
as `ARKit` and `ARCore` need to reserve the camera stream. The correct way is to create
[GDExtension](https://docs.godotengine.org/en/stable/engine_details/engine_api/gdextension/index.html) for iOS, and
[GodotAndroidPlugins](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html) for Android,
then pump the frames (YUV->RGB) and anchor, camera transforms back to Godot.
It is confirmed achievable, because I personally did just that for contracted works.

If you really insist to process AR all inside Godot, you need to fetch the frame and write your own AR algorithm.
A good starting point is use GDExtension to implement [OpenCV](https://opencv.org/) ORB, AKAZE image detection,
but it is even more advanced and not recommended unless you are familliar with math.
