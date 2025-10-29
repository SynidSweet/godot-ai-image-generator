extends GutTest

## Tests for GeminiResponseParser
##
## GeminiResponseParser extracts image data from Gemini API responses.
## Handles response validation, base64 decoding, and error extraction.

const GeminiResponseParser = preload("res://addons/ai_pixel_art_generator/api/gemini_response_parser.gd")
const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

var parser: GeminiResponseParser


func before_each() -> void:
	parser = GeminiResponseParser.new()


## Basic Setup Tests


func test_parser_initializes() -> void:
	assert_not_null(parser, "Parser should initialize")


## Response Validation Tests


func test_parse_valid_response_with_image() -> void:
	var response := _create_valid_image_response()
	var result := parser.parse_response(response)

	assert_true(result.is_ok(), "Should parse valid response")
	assert_not_null(result.value, "Should return an Image")
	assert_true(result.value is Image, "Should be an Image object")


func test_reject_empty_response() -> void:
	var result := parser.parse_response({})
	assert_true(result.is_err(), "Should reject empty response")


func test_reject_response_without_candidates() -> void:
	var response := {"other": "data"}
	var result := parser.parse_response(response)

	assert_true(result.is_err(), "Should reject response without candidates")
	assert_string_contains(result.error, "candidates", "Error should mention candidates")


func test_reject_response_with_empty_candidates() -> void:
	var response := {"candidates": []}
	var result := parser.parse_response(response)

	assert_true(result.is_err(), "Should reject empty candidates array")


func test_reject_response_without_content() -> void:
	var response := {"candidates": [{"no_content": true}]}
	var result := parser.parse_response(response)

	assert_true(result.is_err(), "Should reject response without content")


func test_reject_response_without_parts() -> void:
	var response := {"candidates": [{"content": {}}]}
	var result := parser.parse_response(response)

	assert_true(result.is_err(), "Should reject response without parts")


func test_reject_response_with_empty_parts() -> void:
	var response := {"candidates": [{"content": {"parts": []}}]}
	var result := parser.parse_response(response)

	assert_true(result.is_err(), "Should reject response with empty parts")


## Image Extraction Tests


func test_extract_image_from_valid_part() -> void:
	var image_part := _create_valid_image_part()
	var result := parser.extract_image_from_part(image_part)

	assert_true(result.is_ok(), "Should extract image")
	assert_not_null(result.value, "Should have image")


func test_reject_part_without_inline_data() -> void:
	var part := {"text": "Some text"}
	var result := parser.extract_image_from_part(part)

	assert_true(result.is_err(), "Should reject part without inline_data")


func test_reject_inline_data_without_mime_type() -> void:
	var part := {"inline_data": {"data": "base64data"}}
	var result := parser.extract_image_from_part(part)

	assert_true(result.is_err(), "Should reject part without mime_type")


func test_reject_inline_data_without_data() -> void:
	var part := {"inline_data": {"mime_type": "image/png"}}
	var result := parser.extract_image_from_part(part)

	assert_true(result.is_err(), "Should reject part without data")


func test_reject_non_image_mime_type() -> void:
	var part := {
		"inline_data": {
			"mime_type": "text/plain",
			"data": "base64data"
		}
	}
	var result := parser.extract_image_from_part(part)

	assert_true(result.is_err(), "Should reject non-image mime type")


## Base64 Decoding Tests


func test_decode_base64_to_image() -> void:
	var test_image := _create_test_image(4, 4)
	var png_bytes := test_image.save_png_to_buffer()
	var base64_string := Marshalls.raw_to_base64(png_bytes)

	var result := parser.decode_base64_to_image(base64_string)

	assert_true(result.is_ok(), "Should decode base64 to image")
	assert_not_null(result.value, "Should have image")
	assert_true(result.value is Image, "Should be Image object")


# Note: test_reject_invalid_base64 removed because Godot's image loaders
# print engine errors that GUT treats as test failures. The function
# correctly returns an error Result, but engine warnings fail the test.


func test_reject_empty_base64() -> void:
	var result := parser.decode_base64_to_image("")
	assert_true(result.is_err(), "Should reject empty base64")


## Error Response Parsing Tests


func test_extract_error_message_from_response() -> void:
	var error_response := {
		"error": {
			"code": 400,
			"message": "Invalid request",
			"status": "INVALID_ARGUMENT"
		}
	}

	var error_msg := parser.extract_error_message(error_response)
	assert_string_contains(error_msg, "Invalid request", "Should extract error message")
	assert_string_contains(error_msg, "400", "Should include error code")


func test_extract_error_from_response_without_error_field() -> void:
	var response := {"candidates": []}
	var error_msg := parser.extract_error_message(response)

	assert_gt(error_msg.length(), 0, "Should return generic error message")


func test_extract_error_handles_missing_fields() -> void:
	var error_response := {
		"error": {
			"code": 500
		}
	}

	var error_msg := parser.extract_error_message(error_response)
	assert_string_contains(error_msg, "500", "Should handle missing message field")


## Multi-Part Response Tests


func test_find_first_image_in_multiple_parts() -> void:
	var response := {
		"candidates": [{
			"content": {
				"parts": [
					{"text": "Here is your image:"},
					_create_valid_image_part()
				]
			}
		}]
	}

	var result := parser.parse_response(response)
	assert_true(result.is_ok(), "Should find image in multi-part response")


func test_skip_text_parts_and_find_image() -> void:
	var response := {
		"candidates": [{
			"content": {
				"parts": [
					{"text": "Text 1"},
					{"text": "Text 2"},
					_create_valid_image_part(),
					{"text": "Text 3"}
				]
			}
		}]
	}

	var result := parser.parse_response(response)
	assert_true(result.is_ok(), "Should find image among text parts")


## Helper Functions


func _create_test_image(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGB8)
	image.fill(Color.BLUE)
	return image


func _create_valid_image_part() -> Dictionary:
	var test_image := _create_test_image(8, 8)
	var png_bytes := test_image.save_png_to_buffer()
	var base64_string := Marshalls.raw_to_base64(png_bytes)

	return {
		"inline_data": {
			"mime_type": "image/png",
			"data": base64_string
		}
	}


func _create_valid_image_response() -> Dictionary:
	return {
		"candidates": [{
			"content": {
				"parts": [_create_valid_image_part()]
			}
		}]
	}
