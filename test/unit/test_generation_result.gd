extends GutTest

const GenerationResult = preload("res://addons/ai_pixel_art_generator/models/generation_result.gd")

var logger
var test_image: Image

func before_each() -> void:
	logger = get_logger()
	# Create a simple test image
	test_image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	test_image.fill(Color.RED)

## ============================================================================
## Constructor and Basic Properties
## ============================================================================

func test_generation_result_creation_with_all_properties() -> void:
	var img1 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var img2 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var img3 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var img4 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var polish_imgs: Array[Image] = []

	var result := GenerationResult.new(img1, img2, img3, img4, polish_imgs, 123456)

	assert_not_null(result.original_image, "Original image should be set")
	assert_not_null(result.palette_conformed_image, "Palette conformed image should be set")
	assert_not_null(result.generated_image, "Generated image should be set")
	assert_not_null(result.pixelated_image, "Pixelated image should be set")
	assert_eq(result.polish_iterations.size(), 0, "Polish iterations should be empty")
	assert_eq(result.timestamp, 123456, "Timestamp should be set")

func test_generation_result_default_constructor() -> void:
	var result := GenerationResult.new()

	assert_null(result.original_image, "Default original image should be null")
	assert_null(result.palette_conformed_image, "Default palette conformed image should be null")
	assert_null(result.generated_image, "Default generated image should be null")
	assert_null(result.pixelated_image, "Default pixelated image should be null")
	assert_eq(result.polish_iterations.size(), 0, "Default polish iterations should be empty")
	assert_gt(result.timestamp, 0, "Default timestamp should be generated")

func test_generation_result_with_polish_iterations() -> void:
	var polish_imgs: Array[Image] = []
	polish_imgs.append(Image.create(2, 2, false, Image.FORMAT_RGBA8))
	polish_imgs.append(Image.create(2, 2, false, Image.FORMAT_RGBA8))

	var result := GenerationResult.new(null, null, null, null, polish_imgs, 0)

	assert_eq(result.polish_iterations.size(), 2, "Should have 2 polish iterations")

## ============================================================================
## Add Polish Iteration
## ============================================================================

func test_add_polish_iteration() -> void:
	var result := GenerationResult.new()
	var polish_img := Image.create(2, 2, false, Image.FORMAT_RGBA8)

	result.add_polish_iteration(polish_img)

	assert_eq(result.polish_iterations.size(), 1, "Should have 1 polish iteration")
	assert_eq(result.polish_iterations[0], polish_img, "Should contain the added image")

func test_add_multiple_polish_iterations() -> void:
	var result := GenerationResult.new()

	for i in range(3):
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		result.add_polish_iteration(img)

	assert_eq(result.polish_iterations.size(), 3, "Should have 3 polish iterations")

## ============================================================================
## Get Latest Polished Image
## ============================================================================

func test_get_latest_polished_returns_last_polish_iteration() -> void:
	var result := GenerationResult.new()
	var img1 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var img2 := Image.create(3, 3, false, Image.FORMAT_RGBA8)

	result.add_polish_iteration(img1)
	result.add_polish_iteration(img2)

	var latest_result := result.get_latest_polished()

	assert_true(latest_result.is_ok(), "Should return latest polished image")
	assert_eq(latest_result.value, img2, "Should return the last added image")

func test_get_latest_polished_returns_pixelated_if_no_polish() -> void:
	var pixelated := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var result := GenerationResult.new(null, null, null, pixelated, [], 0)

	var latest_result := result.get_latest_polished()

	assert_true(latest_result.is_ok(), "Should return pixelated image if no polish")
	assert_eq(latest_result.value, pixelated, "Should return pixelated image")

func test_get_latest_polished_returns_error_if_no_images() -> void:
	var result := GenerationResult.new()

	var latest_result := result.get_latest_polished()

	assert_true(latest_result.is_err(), "Should return error if no images")
	assert_string_contains(latest_result.error, "available", "Error should mention no images available")

## ============================================================================
## Get Final Image
## ============================================================================

func test_get_final_image_prefers_polish_over_pixelated() -> void:
	var pixelated := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var polish := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	var result := GenerationResult.new(null, null, null, pixelated, [], 0)
	result.add_polish_iteration(polish)

	var final_result := result.get_final_image()

	assert_true(final_result.is_ok(), "Should return final image")
	assert_eq(final_result.value, polish, "Should prefer polish over pixelated")

func test_get_final_image_returns_pixelated_if_no_polish() -> void:
	var pixelated := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var result := GenerationResult.new(null, null, null, pixelated, [], 0)

	var final_result := result.get_final_image()

	assert_true(final_result.is_ok(), "Should return pixelated image")
	assert_eq(final_result.value, pixelated, "Should return pixelated image")

func test_get_final_image_returns_error_if_no_images() -> void:
	var result := GenerationResult.new()

	var final_result := result.get_final_image()

	assert_true(final_result.is_err(), "Should return error if no images")

## ============================================================================
## Validation
## ============================================================================

func test_validate_returns_ok_for_complete_result() -> void:
	var img1 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var img2 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var img3 := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	var img4 := Image.create(2, 2, false, Image.FORMAT_RGBA8)

	var result := GenerationResult.new(img1, img2, img3, img4, [], 0)

	var validation := result.validate()
	assert_true(validation.is_ok(), "Complete result should pass validation")

func test_validate_fails_if_pixelated_image_missing() -> void:
	var result := GenerationResult.new()
	result.original_image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	result.generated_image = Image.create(2, 2, false, Image.FORMAT_RGBA8)

	var validation := result.validate()
	assert_true(validation.is_err(), "Should fail without pixelated image")
	assert_string_contains(validation.error, "pixelated", "Error should mention pixelated image")
