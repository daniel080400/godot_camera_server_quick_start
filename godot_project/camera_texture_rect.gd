# Minimal code to get Camera feeds from CameraServer (tested on Godot 4.7.1, Linux, Android)
#

extends TextureRect

## Target camera feed index, clamped to the number of connected camera feeds.
## Modify this if you want other feeds like BACK, FRONT cameras, look at the console output for specs
@export var feed_idx: int = 0

## Target resolution width to look for in camera specs.
## If resolution is too high (> 4K), it might cause lags on low-end devices, or not display in at all.
@export var desired_width_px: int = 1600

## Time in seconds to wait for camera activation, 1 second(s) is sufficient on most devices, if this
## is set to too low, might fail to grab camera feed.
@export var camera_activate_delay_secs: float = 1.0

## To convert camera streamed ycbcr (YUV) to rgb on monitor
var ycbcr_conv_mat: ShaderMaterial

# TODO - Edit this to get the shader resource in the project
var ycbcr_conv_shader: Shader = preload("res://ycbcr_to_rgb.gdshader")

enum ShaderMode { RGB = 0, YCBCR_SEP = 1, YCBCR = 2 }
enum ColorRange { FULL = 0, VIDEO = 1 }

## For readability
@onready var cam_texrect: TextureRect = self

## On detected camera on device
func _on_camera_feed_updated() -> void:
	if CameraServer.get_feed_count() == 0:
		# No camera feeds detected
		return

	# DEBUG - List feeds
	print("Detected camera feeds (feed_idx - name):")
	for i in range(0, CameraServer.get_feed_count()):
		var feed_name: String = CameraServer.feeds()[i].get_name()
		print("{0} - {1}".format({ 0: i, 1: feed_name }))
		continue

	# Use desired camera feed
	var feed: CameraFeed
	var last_feed_idx: int = CameraServer.feeds().size() - 1
	if feed_idx > last_feed_idx:
		feed = CameraServer.feeds()[last_feed_idx]
	else:
		feed = CameraServer.feeds()[feed_idx]
		pass

	# DEBUG - List formats
	print("Supported camera feed formats (format_idx - format_dict):")
	for i in range(0, feed.formats.size()):
		print("{0} - {1}".format({ 0: i, 1: feed.formats[i] }))
		continue

	# Use format closest to the desired width
	var format_idx: int = 0
	for i in range(0, feed.formats.size()):
		if feed.formats[i]["width"] <= desired_width_px:
			format_idx = i
			break
		continue

	# Activate the camera feed
	if !feed.feed_is_active:
		feed.set_format(format_idx, {})
		feed.feed_is_active = true

		# HACK - Camera needs time to activate.. 1 second(s) is sufficient on most devices
		await get_tree().create_timer(camera_activate_delay_secs).timeout
		pass

	_setup_camera_feed(feed, format_idx)
	return


## Setup and render camera feed to TextureRect
func _setup_camera_feed(feed: CameraFeed, format_idx: int) -> void:
	# Setup camera textures
	var rgb_texture := CameraTexture.new()
	var y_texture := CameraTexture.new()
	var cbcr_texture := CameraTexture.new()
	var ycbcr_texture := CameraTexture.new()

	rgb_texture.which_feed = CameraServer.FeedImage.FEED_RGBA_IMAGE
	y_texture.which_feed = CameraServer.FeedImage.FEED_Y_IMAGE
	cbcr_texture.which_feed = CameraServer.FeedImage.FEED_CBCR_IMAGE
	ycbcr_texture.which_feed = CameraServer.FeedImage.FEED_YCBCR_IMAGE

	ycbcr_conv_mat.set_shader_parameter(&"color_range", _get_camera_color_range(feed.formats[format_idx]))

	print("Using camera feed name: ", feed.get_name())
	print("Using camera feed id (not index): ", feed.get_id())

	var texture_size: Vector2 = Vector2.ZERO

	match feed.get_datatype():
		CameraFeed.FeedDataType.FEED_RGB:
			print("Camera feed format datatype: FEED_RGB")
			rgb_texture.camera_feed_id = feed.get_id()
			ycbcr_conv_mat.set_shader_parameter(&"rgb_texture", rgb_texture)
			ycbcr_conv_mat.set_shader_parameter(&"mode", ShaderMode.RGB)
			texture_size = rgb_texture.get_size()

		CameraFeed.FeedDataType.FEED_YCBCR:
			print("Camera feed format datatype: FEED_YCBCR")
			ycbcr_texture.camera_feed_id = feed.get_id()
			ycbcr_conv_mat.set_shader_parameter(&"ycbcr_texture", ycbcr_texture)
			ycbcr_conv_mat.set_shader_parameter(&"mode", ShaderMode.YCBCR)
			texture_size = ycbcr_texture.get_size()

		CameraFeed.FeedDataType.FEED_YCBCR_SEP:
			print("Camera feed format datatype: FEED_YCBCR_SEP")
			y_texture.camera_feed_id = feed.get_id()
			cbcr_texture.camera_feed_id = feed.get_id()
			ycbcr_conv_mat.set_shader_parameter(&"y_texture", y_texture)
			ycbcr_conv_mat.set_shader_parameter(&"cbcr_texture", cbcr_texture)
			ycbcr_conv_mat.set_shader_parameter(&"mode", ShaderMode.YCBCR_SEP)
			texture_size = y_texture.get_size()
		_:
			push_error("Failed to fetch camera feed: Camera feed format not supported")
			return

	# Create background blank image as the size of camera's resolution
	var white_image := Image.create(int(texture_size.x), int(texture_size.y), false, Image.FORMAT_RGBA8)
	white_image.fill(Color.WHITE)
	cam_texrect.texture = ImageTexture.create_from_image(white_image)
	print("Camera feed selected resolution: ", texture_size)
	return


func _get_camera_color_range(format: Dictionary) -> int:
	# Specified
	var color_range_str: String = format.get("color_range", "")
	if color_range_str == "full":
		return ColorRange.FULL
	if color_range_str == "video":
		return ColorRange.VIDEO

	# Guess based on platform
	match OS.get_name().to_lower():
		"android":
			return ColorRange.VIDEO
		"windows":
			return ColorRange.VIDEO
		"linux":
			return ColorRange.FULL
		"macos":
			return ColorRange.FULL
		"ios":
			return ColorRange.FULL

	# Default
	return ColorRange.FULL


func _setup_camera_server() -> void:
	CameraServer.camera_feeds_updated.connect(_on_camera_feed_updated)
	CameraServer.monitoring_feeds = true
	return


## On user granted / denied permission
func _on_perms_result(perms: String, granted: bool):
	if perms == "android.permission.CAMERA" && granted:
		_setup_camera_server()
		return

	if !granted:
		push_warning("User did not grant camera permission, abort starting CameraServer")
		return
	return


func _ready() -> void:
	ycbcr_conv_mat = ShaderMaterial.new()
	ycbcr_conv_mat.shader = ycbcr_conv_shader
	cam_texrect.material = ycbcr_conv_mat

	# Android
	# NOTE - On android, remember to request camera permission in export preset settings
	if OS.get_name().to_lower() == "android":
		get_tree().on_request_permissions_result.connect(_on_perms_result)
		var camera_perms_granted: bool = OS.request_permission("android.permission.CAMERA")
		if camera_perms_granted:
			print("Camera permission already granted, setting up camera server")
			_setup_camera_server()
		return

	# PC
	_setup_camera_server()
	return
