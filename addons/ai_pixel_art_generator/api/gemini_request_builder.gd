class_name GeminiRequestBuilder

## Gemini Request Builder
##
## Constructs JSON request payloads for Gemini 2.5 Flash Image API.
## Handles text prompts, image encoding, and generation configuration.
##
## Usage:
##   var builder := GeminiRequestBuilder.new()
##   builder.temperature = 1.0
##   builder.aspect_ratio = "16:9"
##   var result := builder.build_request(prompt, reference_image)
##   if result.is_ok():
##       # Use result.value as request body

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

## AI temperature (0.0 - 2.0). Controls randomness in generation.
var temperature: float = 1.0

## Image aspect ratio for generated images
var aspect_ratio: String = "1:1"

## Valid aspect ratios supported by Gemini API
const VALID_ASPECT_RATIOS: Array[String] = ["1:1", "16:9", "9:16", "4:3", "3:4"]

var _logger: PluginLogger


func _init() -> void:
	_logger = PluginLogger.get_logger("GeminiRequestBuilder")


## Builds a complete request for Gemini API
##
## Args:
##   prompt: Text prompt for generation
##   reference_image: Optional Image to include (for image-to-image)
##
## Returns:
##   Result<Dictionary> containing request body
func build_request(prompt: String, reference_image: Image) -> Result:
	# Validate inputs
	var validation := _validate_inputs(prompt)
	if validation.is_err():
		return validation

	# Build contents array with text and optional image
	var parts: Array[Dictionary] = []

	# Add text prompt
	parts.append({
		"text": prompt
	})

	# Add image if provided
	if reference_image != null:
		var image_result := _build_image_part(reference_image)
		if image_result.is_err():
			return image_result
		parts.append(image_result.value)

	# Build generation config
	var config_result := _build_generation_config()
	if config_result.is_err():
		return config_result

	# Construct final request
	var request: Dictionary = {
		"contents": [{
			"parts": parts
		}],
		"generationConfig": config_result.value
	}

	_logger.debug("Built request", {
		"has_image": reference_image != null,
		"temperature": temperature,
		"aspect_ratio": aspect_ratio
	})

	return Result.ok(request)


## Encodes an Image to base64 PNG string
func encode_image_to_base64(image: Image) -> Result:
	if image == null:
		return Result.err("Cannot encode null image")

	# Save image as PNG to buffer
	var png_bytes := image.save_png_to_buffer()
	if png_bytes.is_empty():
		return Result.err("Failed to encode image as PNG")

	# Convert to base64
	var base64_string := Marshalls.raw_to_base64(png_bytes)
	if base64_string.is_empty():
		return Result.err("Failed to encode PNG to base64")

	return Result.ok(base64_string)


## Resets builder to default settings
func reset() -> void:
	temperature = 1.0
	aspect_ratio = "1:1"


## Validates request inputs
func _validate_inputs(prompt: String) -> Result:
	# Check prompt
	if prompt.is_empty():
		return Result.err("Prompt cannot be empty")

	if prompt.strip_edges().is_empty():
		return Result.err("Prompt cannot be whitespace only")

	# Validate temperature
	if temperature < 0.0 or temperature > 2.0:
		return Result.err("Temperature must be between 0.0 and 2.0 (got: %.2f)" % temperature)

	# Validate aspect ratio
	if aspect_ratio not in VALID_ASPECT_RATIOS:
		return Result.err("Invalid aspect ratio: %s (valid: %s)" % [
			aspect_ratio,
			", ".join(VALID_ASPECT_RATIOS)
		])

	return Result.ok(true)


## Builds the image part for inline_data
func _build_image_part(image: Image) -> Result:
	var base64_result := encode_image_to_base64(image)
	if base64_result.is_err():
		return base64_result

	var image_part: Dictionary = {
		"inline_data": {
			"mime_type": "image/png",
			"data": base64_result.value
		}
	}

	return Result.ok(image_part)


## Builds the generation configuration
func _build_generation_config() -> Result:
	var config: Dictionary = {
		"responseModalities": ["Image"],
		"imageConfig": {
			"aspectRatio": aspect_ratio
		}
	}

	# Only include temperature if not default (1.0)
	if temperature != 1.0:
		config["temperature"] = temperature

	return Result.ok(config)
