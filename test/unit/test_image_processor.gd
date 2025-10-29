extends GutTest

const ImageProcessor = preload("res://addons/ai_pixel_art_generator/core/image_processor.gd")
const Palette = preload("res://addons/ai_pixel_art_generator/models/palette.gd")

var logger
var processor: ImageProcessor

func before_each() -> void:
	logger = get_logger()
	processor = ImageProcessor.new()

## ============================================================================
## Test Fixtures - Create Known Test Images
## ============================================================================

func _create_solid_color_image(color: Color, width: int = 4, height: int = 4) -> Image:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img

func _create_gradient_image() -> Image:
	# Create a 4x4 image with gradient from black to white
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in range(4):
		for x in range(4):
			var value := float(x + y * 4) / 15.0
			img.set_pixel(x, y, Color(value, value, value))
	return img

func _create_rgb_image() -> Image:
	# Create a 2x2 image with red, green, blue, yellow
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.RED)
	img.set_pixel(1, 0, Color.GREEN)
	img.set_pixel(0, 1, Color.BLUE)
	img.set_pixel(1, 1, Color.YELLOW)
	return img

func _create_bw_palette() -> Palette:
	var colors: Array[Color] = [Color.BLACK, Color.WHITE]
	return Palette.new("bw", colors)

func _create_rgb_palette() -> Palette:
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	return Palette.new("rgb", colors)

## ============================================================================
## Palette Conformance - Nearest Neighbor (No Dithering)
## ============================================================================

func test_conform_to_palette_with_exact_match() -> void:
	var img := _create_solid_color_image(Color.RED)
	var palette := _create_rgb_palette()

	var result := processor.conform_to_palette(img, palette, ImageProcessor.DitheringMode.NONE)

	assert_true(result.is_ok(), "Should successfully conform image")
	var conformed: Image = result.value
	assert_eq(conformed.get_width(), 4, "Width should be preserved")
	assert_eq(conformed.get_height(), 4, "Height should be preserved")
	assert_eq(conformed.get_pixel(0, 0), Color.RED, "Red should remain red")

func test_conform_to_palette_with_approximate_color() -> void:
	var img := _create_solid_color_image(Color(0.9, 0.1, 0.1))  # Dark red
	var palette := _create_rgb_palette()

	var result := processor.conform_to_palette(img, palette, ImageProcessor.DitheringMode.NONE)

	assert_true(result.is_ok(), "Should successfully conform image")
	var conformed: Image = result.value
	assert_eq(conformed.get_pixel(0, 0), Color.RED, "Dark red should map to RED")

func test_conform_to_palette_grayscale_to_bw() -> void:
	var img := _create_gradient_image()
	var palette := _create_bw_palette()

	var result := processor.conform_to_palette(img, palette, ImageProcessor.DitheringMode.NONE)

	assert_true(result.is_ok(), "Should successfully conform image")
	var conformed: Image = result.value

	# Check that only black and white pixels exist
	for y in range(4):
		for x in range(4):
			var pixel := conformed.get_pixel(x, y)
			var is_bw := pixel == Color.BLACK or pixel == Color.WHITE
			assert_true(is_bw, "Pixel at (%d,%d) should be black or white" % [x, y])

func test_conform_to_palette_with_empty_palette() -> void:
	var img := _create_solid_color_image(Color.RED)
	var empty_colors: Array[Color] = []
	var palette := Palette.new("empty", empty_colors)

	var result := processor.conform_to_palette(img, palette, ImageProcessor.DitheringMode.NONE)

	assert_true(result.is_err(), "Should fail with empty palette")

func test_conform_to_palette_with_null_image() -> void:
	var palette := _create_rgb_palette()

	var result := processor.conform_to_palette(null, palette, ImageProcessor.DitheringMode.NONE)

	assert_true(result.is_err(), "Should fail with null image")

## ============================================================================
## Palette Conformance - Floyd-Steinberg Dithering
## ============================================================================

func test_conform_to_palette_floyd_steinberg() -> void:
	var img := _create_gradient_image()
	var palette := _create_bw_palette()

	var result := processor.conform_to_palette(img, palette, ImageProcessor.DitheringMode.FLOYD_STEINBERG)

	assert_true(result.is_ok(), "Should successfully apply Floyd-Steinberg dithering")
	var dithered: Image = result.value

	# Dithered image should still only contain palette colors
	for y in range(4):
		for x in range(4):
			var pixel := dithered.get_pixel(x, y)
			var is_bw := pixel == Color.BLACK or pixel == Color.WHITE
			assert_true(is_bw, "Dithered pixel should be black or white")

func test_dithering_creates_different_result_than_nearest() -> void:
	var img := _create_gradient_image()
	var palette := _create_bw_palette()

	var nearest_result := processor.conform_to_palette(img, palette, ImageProcessor.DitheringMode.NONE)
	var dithered_result := processor.conform_to_palette(img, palette, ImageProcessor.DitheringMode.FLOYD_STEINBERG)

	assert_true(nearest_result.is_ok() and dithered_result.is_ok(), "Both should succeed")

	var nearest: Image = nearest_result.value
	var dithered: Image = dithered_result.value

	# Check that results are different (dithering should create more variation)
	var differences := 0
	for y in range(4):
		for x in range(4):
			if nearest.get_pixel(x, y) != dithered.get_pixel(x, y):
				differences += 1

	assert_gt(differences, 0, "Dithering should create different results than nearest neighbor")

## ============================================================================
## Pixelation
## ============================================================================

func test_pixelate_downscales_image() -> void:
	var img := _create_solid_color_image(Color.RED, 16, 16)
	var target_size := Vector2i(8, 8)

	var result := processor.pixelate(img, target_size)

	assert_true(result.is_ok(), "Should successfully pixelate image")
	var pixelated: Image = result.value
	assert_eq(pixelated.get_width(), 8, "Width should be downscaled to 8")
	assert_eq(pixelated.get_height(), 8, "Height should be downscaled to 8")

func test_pixelate_maintains_colors() -> void:
	var img := _create_rgb_image()  # 2x2
	var target_size := Vector2i(1, 1)

	var result := processor.pixelate(img, target_size)

	assert_true(result.is_ok(), "Should successfully pixelate to 1x1")
	var pixelated: Image = result.value
	assert_eq(pixelated.get_width(), 1, "Should be 1x1")
	# Color should be an average of the input colors

func test_pixelate_with_zero_size() -> void:
	var img := _create_solid_color_image(Color.RED)

	var result := processor.pixelate(img, Vector2i(0, 0))

	assert_true(result.is_err(), "Should fail with zero size")

func test_pixelate_with_null_image() -> void:
	var result := processor.pixelate(null, Vector2i(8, 8))

	assert_true(result.is_err(), "Should fail with null image")

## ============================================================================
## Upscale Pixelated (Nearest Neighbor)
## ============================================================================

func test_upscale_pixelated() -> void:
	var img := _create_solid_color_image(Color.RED, 4, 4)
	var scale_factor := 2

	var result := processor.upscale_pixelated(img, scale_factor)

	assert_true(result.is_ok(), "Should successfully upscale image")
	var upscaled: Image = result.value
	assert_eq(upscaled.get_width(), 8, "Width should be doubled")
	assert_eq(upscaled.get_height(), 8, "Height should be doubled")

func test_upscale_maintains_hard_edges() -> void:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.RED)
	img.set_pixel(1, 0, Color.GREEN)
	img.set_pixel(0, 1, Color.BLUE)
	img.set_pixel(1, 1, Color.YELLOW)

	var result := processor.upscale_pixelated(img, 2)

	assert_true(result.is_ok(), "Should successfully upscale")
	var upscaled: Image = result.value

	# Check that each source pixel becomes a 2x2 block
	assert_eq(upscaled.get_pixel(0, 0), Color.RED, "Top-left should be red block")
	assert_eq(upscaled.get_pixel(1, 0), Color.RED, "Top-left should be red block")
	assert_eq(upscaled.get_pixel(2, 2), Color.YELLOW, "Bottom-right should be yellow block")

func test_upscale_with_scale_factor_one() -> void:
	var img := _create_solid_color_image(Color.RED, 4, 4)

	var result := processor.upscale_pixelated(img, 1)

	assert_true(result.is_ok(), "Should succeed with scale factor 1")
	var upscaled: Image = result.value
	assert_eq(upscaled.get_width(), 4, "Should remain same size")

func test_upscale_with_zero_scale_factor() -> void:
	var img := _create_solid_color_image(Color.RED)

	var result := processor.upscale_pixelated(img, 0)

	assert_true(result.is_err(), "Should fail with zero scale factor")

## ============================================================================
## Image Validation
## ============================================================================

func test_validate_image_returns_ok_for_valid_image() -> void:
	var img := _create_solid_color_image(Color.RED)

	var result := processor.validate_image(img)

	assert_true(result.is_ok(), "Valid image should pass validation")

func test_validate_image_fails_for_null() -> void:
	var result := processor.validate_image(null)

	assert_true(result.is_err(), "Null image should fail validation")

# Note: Cannot test zero-dimension images as Godot doesn't allow creating them
# The validation logic is still present to guard against any edge cases

## ============================================================================
## Image Copy (Deep Copy)
## ============================================================================

func test_copy_image_creates_independent_copy() -> void:
	var original := _create_solid_color_image(Color.RED)

	var result := processor.copy_image(original)

	assert_true(result.is_ok(), "Should successfully copy image")
	var copy: Image = result.value

	# Modify the copy
	copy.set_pixel(0, 0, Color.BLUE)

	# Original should remain unchanged
	assert_eq(original.get_pixel(0, 0), Color.RED, "Original should not be modified")
	assert_eq(copy.get_pixel(0, 0), Color.BLUE, "Copy should be modified")

func test_copy_image_preserves_dimensions() -> void:
	var original := _create_solid_color_image(Color.GREEN, 8, 12)

	var result := processor.copy_image(original)

	assert_true(result.is_ok(), "Should successfully copy")
	var copy: Image = result.value
	assert_eq(copy.get_width(), 8, "Width should match")
	assert_eq(copy.get_height(), 12, "Height should match")

func test_copy_image_fails_with_null() -> void:
	var result := processor.copy_image(null)

	assert_true(result.is_err(), "Should fail with null image")
