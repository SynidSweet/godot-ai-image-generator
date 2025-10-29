extends GutTest

## Tests for GeminiRequestBuilder
##
## GeminiRequestBuilder constructs JSON payloads for Gemini 2.5 Flash Image API.
## It handles text prompts, image encoding, and generation configuration.

const GeminiRequestBuilder = preload("res://addons/ai_pixel_art_generator/api/gemini_request_builder.gd")
const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

var builder: GeminiRequestBuilder


func before_each() -> void:
	builder = GeminiRequestBuilder.new()


## Basic Request Tests


func test_builder_initializes() -> void:
	assert_not_null(builder, "Builder should initialize")


func test_build_text_only_request() -> void:
	var result := builder.build_request("Generate a pixel art tree", null)

	assert_true(result.is_ok(), "Should build request successfully")

	var request: Dictionary = result.value
	assert_has(request, "contents", "Should have contents")
	assert_has(request, "generationConfig", "Should have generationConfig")


func test_text_only_request_structure() -> void:
	var result := builder.build_request("Test prompt", null)
	var request: Dictionary = result.value

	var contents: Array = request["contents"]
	assert_eq(contents.size(), 1, "Should have one content block")

	var parts: Array = contents[0]["parts"]
	assert_eq(parts.size(), 1, "Should have one part (text)")
	assert_eq(parts[0]["text"], "Test prompt", "Should contain the prompt")


func test_reject_empty_prompt() -> void:
	var result := builder.build_request("", null)
	assert_true(result.is_err(), "Should reject empty prompt")
	assert_string_contains(result.error, "empty", "Error should mention empty")


func test_reject_whitespace_only_prompt() -> void:
	var result := builder.build_request("   ", null)
	assert_true(result.is_err(), "Should reject whitespace-only prompt")


## Image Encoding Tests


func test_build_request_with_image() -> void:
	var image := _create_test_image(4, 4)
	var result := builder.build_request("Edit this image", image)

	assert_true(result.is_ok(), "Should build request with image")

	var request: Dictionary = result.value
	var parts: Array = request["contents"][0]["parts"]
	assert_eq(parts.size(), 2, "Should have two parts (text + image)")


func test_image_part_structure() -> void:
	var image := _create_test_image(4, 4)
	var result := builder.build_request("Test", image)
	var request: Dictionary = result.value

	var parts: Array = request["contents"][0]["parts"]
	var image_part: Dictionary = parts[1]

	assert_has(image_part, "inline_data", "Should have inline_data")
	assert_has(image_part["inline_data"], "mime_type", "Should have mime_type")
	assert_has(image_part["inline_data"], "data", "Should have data")
	assert_eq(image_part["inline_data"]["mime_type"], "image/png", "Should be PNG")


func test_image_is_base64_encoded() -> void:
	var image := _create_test_image(4, 4)
	var result := builder.build_request("Test", image)
	var request: Dictionary = result.value

	var parts: Array = request["contents"][0]["parts"]
	var image_data: String = parts[1]["inline_data"]["data"]

	assert_gt(image_data.length(), 0, "Should have image data")
	# Base64 encoded data should not be empty and should be a valid string
	assert_false(image_data.is_empty(), "Base64 should not be empty")


func test_encode_image_to_base64() -> void:
	var image := _create_test_image(8, 8)
	var result := builder.encode_image_to_base64(image)

	assert_true(result.is_ok(), "Should encode image")
	assert_gt(result.value.length(), 0, "Should have encoded data")


func test_encode_null_image_fails() -> void:
	var result := builder.encode_image_to_base64(null)
	assert_true(result.is_err(), "Should reject null image")


## Generation Config Tests


func test_default_generation_config() -> void:
	var result := builder.build_request("Test", null)
	var request: Dictionary = result.value

	var config: Dictionary = request["generationConfig"]
	assert_has(config, "responseModalities", "Should have responseModalities")

	var modalities: Array = config["responseModalities"]
	assert_has(modalities, "Image", "Should request Image response")


func test_generation_config_with_temperature() -> void:
	builder.temperature = 0.8
	var result := builder.build_request("Test", null)
	var request: Dictionary = result.value

	var config: Dictionary = request["generationConfig"]
	assert_has(config, "temperature", "Should have temperature")
	assert_eq(config["temperature"], 0.8, "Should set temperature")


func test_temperature_validation() -> void:
	builder.temperature = -0.5
	var result := builder.build_request("Test", null)
	assert_true(result.is_err(), "Should reject negative temperature")

	builder.temperature = 3.0
	result = builder.build_request("Test", null)
	assert_true(result.is_err(), "Should reject temperature > 2.0")


func test_temperature_range_valid() -> void:
	builder.temperature = 0.0
	var result := builder.build_request("Test", null)
	assert_true(result.is_ok(), "Should accept temperature 0.0")

	builder.temperature = 1.0
	result = builder.build_request("Test", null)
	assert_true(result.is_ok(), "Should accept temperature 1.0")

	builder.temperature = 2.0
	result = builder.build_request("Test", null)
	assert_true(result.is_ok(), "Should accept temperature 2.0")


func test_aspect_ratio_in_config() -> void:
	builder.aspect_ratio = "16:9"
	var result := builder.build_request("Test", null)
	var request: Dictionary = result.value

	var config: Dictionary = request["generationConfig"]
	assert_has(config, "imageConfig", "Should have imageConfig")
	assert_has(config["imageConfig"], "aspectRatio", "Should have aspectRatio")
	assert_eq(config["imageConfig"]["aspectRatio"], "16:9", "Should set aspect ratio")


func test_aspect_ratio_validation() -> void:
	var valid_ratios := ["1:1", "16:9", "9:16", "4:3", "3:4"]

	for ratio in valid_ratios:
		builder.aspect_ratio = ratio
		var result := builder.build_request("Test", null)
		assert_true(result.is_ok(), "Should accept valid ratio: %s" % ratio)


func test_aspect_ratio_rejects_invalid() -> void:
	builder.aspect_ratio = "invalid"
	var result := builder.build_request("Test", null)
	assert_true(result.is_err(), "Should reject invalid aspect ratio")


## Complete Request Example Test


func test_complete_request_with_all_options() -> void:
	var image := _create_test_image(16, 16)
	builder.temperature = 1.5  # Use non-default value
	builder.aspect_ratio = "16:9"

	var result := builder.build_request("Generate a pixel art landscape", image)

	assert_true(result.is_ok(), "Should build complete request")

	var request: Dictionary = result.value

	# Check contents
	assert_has(request, "contents", "Should have contents")
	var parts: Array = request["contents"][0]["parts"]
	assert_eq(parts.size(), 2, "Should have prompt + image")

	# Check generation config
	var config: Dictionary = request["generationConfig"]
	assert_eq(config["temperature"], 1.5, "Should have temperature")
	assert_eq(config["imageConfig"]["aspectRatio"], "16:9", "Should have aspect ratio")


## Reset Test


func test_reset_clears_settings() -> void:
	builder.temperature = 1.5
	builder.aspect_ratio = "16:9"

	builder.reset()

	assert_eq(builder.temperature, 1.0, "Should reset temperature to default")
	assert_eq(builder.aspect_ratio, "1:1", "Should reset aspect ratio to default")


## Helper Functions


func _create_test_image(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	return image
