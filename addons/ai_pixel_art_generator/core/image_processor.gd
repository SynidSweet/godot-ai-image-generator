## ImageProcessor
##
## Pure image processing functions for pixel art generation pipeline.
## All functions are deterministic with no side effects or I/O.
##
## Usage:
##   const ImageProcessor = preload("res://addons/ai_pixel_art_generator/core/image_processor.gd")
##   var processor := ImageProcessor.new()
##   var result := processor.conform_to_palette(image, palette, DitheringMode.FLOYD_STEINBERG)

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const Palette = preload("res://addons/ai_pixel_art_generator/models/palette.gd")

## Dithering modes for palette conformance
enum DitheringMode {
	NONE,              ## Nearest neighbor (no dithering)
	FLOYD_STEINBERG    ## Floyd-Steinberg error diffusion dithering
}

## Conforms an image to a color palette
##
## Parameters:
##   image: Source image to conform
##   palette: Target color palette
##   dithering: Dithering mode to use
##
## Returns:
##   Result<Image>: Conformed image or error
func conform_to_palette(image: Image, palette: Palette, dithering: DitheringMode = DitheringMode.NONE) -> Result:
	# Validate inputs
	var img_validation := validate_image(image)
	if img_validation.is_err():
		return img_validation

	var palette_validation := palette.validate()
	if palette_validation.is_err():
		return Result.err("Invalid palette: " + palette_validation.error)

	# Choose dithering algorithm
	match dithering:
		DitheringMode.NONE:
			return _conform_nearest_neighbor(image, palette)
		DitheringMode.FLOYD_STEINBERG:
			return _conform_floyd_steinberg(image, palette)
		_:
			return Result.err("Unknown dithering mode")

## Pixelates an image by downscaling to target resolution
##
## Uses nearest-neighbor sampling for sharp pixel art look.
##
## Parameters:
##   image: Source image
##   target_size: Target resolution (width, height)
##
## Returns:
##   Result<Image>: Pixelated image or error
func pixelate(image: Image, target_size: Vector2i) -> Result:
	var img_validation := validate_image(image)
	if img_validation.is_err():
		return img_validation

	if target_size.x <= 0 or target_size.y <= 0:
		return Result.err("Target size must be positive (got %s)" % target_size)

	# Create new image at target size
	var pixelated := Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)

	# Downsample using nearest neighbor
	for y in range(target_size.y):
		for x in range(target_size.x):
			# Map target pixel to source pixel
			var src_x := int(float(x) / target_size.x * image.get_width())
			var src_y := int(float(y) / target_size.y * image.get_height())
			src_x = clampi(src_x, 0, image.get_width() - 1)
			src_y = clampi(src_y, 0, image.get_height() - 1)

			var color := image.get_pixel(src_x, src_y)
			pixelated.set_pixel(x, y, color)

	return Result.ok(pixelated)

## Upscales a pixelated image using nearest-neighbor to maintain hard edges
##
## Parameters:
##   image: Source pixelated image
##   scale_factor: Integer scale factor (e.g., 2 = double size)
##
## Returns:
##   Result<Image>: Upscaled image or error
func upscale_pixelated(image: Image, scale_factor: int) -> Result:
	var img_validation := validate_image(image)
	if img_validation.is_err():
		return img_validation

	if scale_factor <= 0:
		return Result.err("Scale factor must be positive (got %d)" % scale_factor)

	if scale_factor == 1:
		# No scaling needed, return copy
		return copy_image(image)

	var new_width := image.get_width() * scale_factor
	var new_height := image.get_height() * scale_factor
	var upscaled := Image.create(new_width, new_height, false, Image.FORMAT_RGBA8)

	# Nearest neighbor upscaling (each pixel becomes scale_factor x scale_factor block)
	for src_y in range(image.get_height()):
		for src_x in range(image.get_width()):
			var color := image.get_pixel(src_x, src_y)

			# Fill the corresponding block in the upscaled image
			for dy in range(scale_factor):
				for dx in range(scale_factor):
					var dst_x := src_x * scale_factor + dx
					var dst_y := src_y * scale_factor + dy
					upscaled.set_pixel(dst_x, dst_y, color)

	return Result.ok(upscaled)

## Validates that an image is non-null and has non-zero dimensions
##
## Parameters:
##   image: Image to validate
##
## Returns:
##   Result: Ok if valid, Err with message if invalid
func validate_image(image: Image) -> Result:
	if image == null:
		return Result.err("Image is null")

	if image.get_width() <= 0 or image.get_height() <= 0:
		return Result.err("Image has invalid dimensions: %dx%d" % [image.get_width(), image.get_height()])

	return Result.ok(true)

## Creates a deep copy of an image
##
## Parameters:
##   image: Image to copy
##
## Returns:
##   Result<Image>: Copied image or error
func copy_image(image: Image) -> Result:
	var img_validation := validate_image(image)
	if img_validation.is_err():
		return img_validation

	# Create new image with same properties
	var copy := Image.create(image.get_width(), image.get_height(), false, image.get_format())

	# Copy pixel data
	copy.copy_from(image)

	return Result.ok(copy)

## ============================================================================
## Private Helper Functions
## ============================================================================

## Conforms image to palette using nearest neighbor (no dithering)
func _conform_nearest_neighbor(image: Image, palette: Palette) -> Result:
	var copy_result := copy_image(image)
	if copy_result.is_err():
		return copy_result

	var conformed: Image = copy_result.value

	# Replace each pixel with nearest palette color
	for y in range(conformed.get_height()):
		for x in range(conformed.get_width()):
			var pixel := conformed.get_pixel(x, y)
			var nearest_result := palette.find_nearest_color(pixel)

			if nearest_result.is_err():
				return nearest_result

			conformed.set_pixel(x, y, nearest_result.value)

	return Result.ok(conformed)

## Conforms image to palette using Floyd-Steinberg error diffusion dithering
func _conform_floyd_steinberg(image: Image, palette: Palette) -> Result:
	var copy_result := copy_image(image)
	if copy_result.is_err():
		return copy_result

	var dithered: Image = copy_result.value
	var width := dithered.get_width()
	var height := dithered.get_height()

	# Floyd-Steinberg error diffusion matrix:
	#     X   7/16
	# 3/16 5/16 1/16
	#
	# Process left-to-right, top-to-bottom
	for y in range(height):
		for x in range(width):
			var old_pixel := dithered.get_pixel(x, y)

			# Find nearest palette color
			var nearest_result := palette.find_nearest_color(old_pixel)
			if nearest_result.is_err():
				return nearest_result

			var new_pixel: Color = nearest_result.value
			dithered.set_pixel(x, y, new_pixel)

			# Calculate quantization error
			var error_r := old_pixel.r - new_pixel.r
			var error_g := old_pixel.g - new_pixel.g
			var error_b := old_pixel.b - new_pixel.b

			# Distribute error to neighboring pixels
			_distribute_error(dithered, x + 1, y, error_r, error_g, error_b, 7.0 / 16.0)
			_distribute_error(dithered, x - 1, y + 1, error_r, error_g, error_b, 3.0 / 16.0)
			_distribute_error(dithered, x, y + 1, error_r, error_g, error_b, 5.0 / 16.0)
			_distribute_error(dithered, x + 1, y + 1, error_r, error_g, error_b, 1.0 / 16.0)

	return Result.ok(dithered)

## Distributes quantization error to a neighboring pixel
func _distribute_error(image: Image, x: int, y: int, error_r: float, error_g: float, error_b: float, factor: float) -> void:
	# Check bounds
	if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
		return

	var pixel := image.get_pixel(x, y)
	var new_r := clampf(pixel.r + error_r * factor, 0.0, 1.0)
	var new_g := clampf(pixel.g + error_g * factor, 0.0, 1.0)
	var new_b := clampf(pixel.b + error_b * factor, 0.0, 1.0)

	image.set_pixel(x, y, Color(new_r, new_g, new_b, pixel.a))
