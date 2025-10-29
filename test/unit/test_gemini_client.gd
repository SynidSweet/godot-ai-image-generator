extends GutTest

## Tests for GeminiClient
##
## GeminiClient provides the high-level API for generating images via Gemini 2.5 Flash Image.

const GeminiClient = preload("res://addons/ai_pixel_art_generator/api/gemini_client.gd")
const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

var client: GeminiClient


func before_each() -> void:
	client = GeminiClient.new("test-api-key")
	add_child(client)


func after_each() -> void:
	if client:
		client.queue_free()
		client = null


## Initialization Tests


func test_client_initializes_with_api_key() -> void:
	assert_not_null(client, "Client should initialize")
	assert_eq(client.api_key, "test-api-key", "Should store API key")


func test_client_has_default_model() -> void:
	assert_eq(client.model_name, "gemini-2.5-flash-image", "Should use correct model")


func test_client_has_default_endpoint() -> void:
	var expected := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"
	assert_eq(client.get_endpoint_url(), expected, "Should use correct endpoint")


## Configuration Tests


func test_can_set_temperature() -> void:
	var result := client.set_temperature(1.5)
	assert_true(result.is_ok(), "Should set temperature")
	assert_eq(client.temperature, 1.5, "Temperature should be updated")


func test_can_set_aspect_ratio() -> void:
	var result := client.set_aspect_ratio("16:9")
	assert_true(result.is_ok(), "Should set aspect ratio")
	assert_eq(client.aspect_ratio, "16:9", "Aspect ratio should be updated")


func test_temperature_validation() -> void:
	var result := client.set_temperature(-0.5)
	assert_true(result.is_err(), "Should reject negative temperature")

	result = client.set_temperature(3.0)
	assert_true(result.is_err(), "Should reject temperature > 2.0")

	result = client.set_temperature(1.0)
	assert_true(result.is_ok(), "Should accept valid temperature")


func test_aspect_ratio_validation() -> void:
	var result := client.set_aspect_ratio("invalid")
	assert_true(result.is_err(), "Should reject invalid aspect ratio")

	result = client.set_aspect_ratio("16:9")
	assert_true(result.is_ok(), "Should accept valid aspect ratio")


## Request Preparation Tests


func test_prepare_headers() -> void:
	var headers := client.prepare_headers()

	assert_has(headers, "x-goog-api-key", "Should have API key header")
	assert_eq(headers["x-goog-api-key"], "test-api-key", "Should include API key")


func test_validate_prompt() -> void:
	var result := client.validate_prompt("")
	assert_true(result.is_err(), "Should reject empty prompt")

	result = client.validate_prompt("Valid prompt")
	assert_true(result.is_ok(), "Should accept valid prompt")


func test_validate_api_key() -> void:
	var result := client.validate_api_key()
	assert_true(result.is_ok(), "Should accept test API key")


## API Call Validation Tests


func test_validate_inputs_before_generate() -> void:
	var validation := client.validate_generation_inputs("Valid prompt", null)
	assert_true(validation.is_ok(), "Should validate correct inputs")


func test_reject_empty_prompt_in_validation() -> void:
	var validation := client.validate_generation_inputs("", null)
	assert_true(validation.is_err(), "Should reject empty prompt")


## Configuration Reset


func test_reset_to_defaults() -> void:
	var _result1 := client.set_temperature(1.5)
	var _result2 := client.set_aspect_ratio("16:9")

	client.reset_to_defaults()

	assert_eq(client.temperature, 1.0, "Should reset temperature")
	assert_eq(client.aspect_ratio, "1:1", "Should reset aspect ratio")


## Error Handling


func test_handles_missing_api_key() -> void:
	var client_no_key := GeminiClient.new("")
	add_child(client_no_key)

	var result := client_no_key.validate_api_key()
	assert_true(result.is_err(), "Should detect missing API key")
	assert_string_contains(result.error, "API key", "Error should mention API key")

	client_no_key.queue_free()
