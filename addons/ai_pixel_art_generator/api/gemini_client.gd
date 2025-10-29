extends Node
class_name GeminiClient

## Gemini API Client
##
## High-level client for Gemini 2.5 Flash Image API ("Nano Banana").
## Provides simple interface for generating and editing images.
##
## Usage:
##   var client := GeminiClient.new(api_key)
##   add_child(client)
##   client.generation_complete.connect(_on_generation_complete)
##   client.set_temperature(1.2)
##   client.set_aspect_ratio("16:9")
##   client.generate_image("A pixel art tree", reference_image)

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")
const HttpClient = preload("res://addons/ai_pixel_art_generator/api/http_client.gd")
const GeminiRequestBuilder = preload("res://addons/ai_pixel_art_generator/api/gemini_request_builder.gd")
const GeminiResponseParser = preload("res://addons/ai_pixel_art_generator/api/gemini_response_parser.gd")

## Signal emitted when image generation completes (success or failure)
## Emits a Result object (either Ok with Image, or Err with error message)
signal generation_complete(result)

## API key for authentication
var api_key: String

## Model name (default: gemini-2.5-flash-image)
var model_name: String = "gemini-2.5-flash-image"

## AI temperature (0.0 - 2.0)
var temperature: float = 1.0

## Image aspect ratio
var aspect_ratio: String = "1:1"

## Base API endpoint
const API_BASE: String = "https://generativelanguage.googleapis.com/v1beta"

var _http_client: HttpClient
var _request_builder: GeminiRequestBuilder
var _response_parser: GeminiResponseParser
var _logger: PluginLogger


func _init(key: String) -> void:
	api_key = key
	_logger = PluginLogger.get_logger("GeminiClient")
	_request_builder = GeminiRequestBuilder.new()
	_response_parser = GeminiResponseParser.new()


func _ready() -> void:
	_http_client = HttpClient.new()
	add_child(_http_client)
	_http_client.request_completed.connect(_on_request_completed)


## Generates an image from a text prompt
##
## Args:
##   prompt: Text description of the desired image
##   reference_image: Optional reference image for image-to-image generation
func generate_image(prompt: String, reference_image: Image = null) -> void:
	# Validate inputs
	var validation := validate_generation_inputs(prompt, reference_image)
	if validation.is_err():
		_emit_error(validation.error)
		return

	# Build request
	_request_builder.temperature = temperature
	_request_builder.aspect_ratio = aspect_ratio

	var request_result := _request_builder.build_request(prompt, reference_image)
	if request_result.is_err():
		_emit_error("Failed to build request: %s" % request_result.error)
		return

	# Prepare headers and make request
	var headers := prepare_headers()
	var url := get_endpoint_url()

	_logger.info("Generating image", {
		"prompt_length": len(prompt),
		"has_reference": reference_image != null,
		"temperature": temperature,
		"aspect_ratio": aspect_ratio
	})

	_http_client.post_json(url, headers, request_result.value)


## Validates inputs for image generation
func validate_generation_inputs(prompt: String, _reference_image: Image) -> Result:
	var api_validation := validate_api_key()
	if api_validation.is_err():
		return api_validation

	var prompt_validation := validate_prompt(prompt)
	if prompt_validation.is_err():
		return prompt_validation

	return Result.ok(true)


## Validates the API key
func validate_api_key() -> Result:
	if api_key.is_empty():
		return Result.err("API key is empty. Configure it in plugin settings.")

	if api_key.strip_edges().is_empty():
		return Result.err("API key is whitespace only")

	return Result.ok(true)


## Validates a prompt string
func validate_prompt(prompt: String) -> Result:
	if prompt.is_empty():
		return Result.err("Prompt cannot be empty")

	if prompt.strip_edges().is_empty():
		return Result.err("Prompt cannot be whitespace only")

	return Result.ok(true)


## Sets temperature with validation
func set_temperature(value: float) -> Result:
	if value < 0.0 or value > 2.0:
		return Result.err("Temperature must be between 0.0 and 2.0")

	temperature = value
	return Result.ok(true)


## Sets aspect ratio with validation
func set_aspect_ratio(ratio: String) -> Result:
	var valid_ratios := ["1:1", "16:9", "9:16", "4:3", "3:4"]
	if ratio not in valid_ratios:
		return Result.err("Invalid aspect ratio: %s" % ratio)

	aspect_ratio = ratio
	return Result.ok(true)


## Resets configuration to defaults
func reset_to_defaults() -> void:
	temperature = 1.0
	aspect_ratio = "1:1"


## Prepares HTTP headers for API request
func prepare_headers() -> Dictionary:
	return {
		"x-goog-api-key": api_key
	}


## Gets the full API endpoint URL
func get_endpoint_url() -> String:
	return "%s/models/%s:generateContent" % [API_BASE, model_name]


## Internal callback when HTTP request completes
func _on_request_completed(http_result: Result) -> void:
	if http_result.is_err():
		_emit_error("HTTP request failed: %s" % http_result.error)
		return

	var response_dict: Dictionary = http_result.value

	# Parse response to extract image
	var parse_result := _response_parser.parse_response(response_dict)

	if parse_result.is_err():
		_emit_error("Failed to parse response: %s" % parse_result.error)
		return

	var image: Image = parse_result.value
	_logger.info("Image generation successful", {
		"width": image.get_width(),
		"height": image.get_height()
	})

	generation_complete.emit(Result.ok(image))


## Emits an error result
func _emit_error(error_message: String) -> void:
	_logger.error("Generation failed", {"error": error_message})
	generation_complete.emit(Result.err(error_message))
