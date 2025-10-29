extends GutTest

## Tests for HttpClient
##
## HttpClient is a thin wrapper around Godot's HTTPRequest node
## providing a cleaner async interface with Result<T> error handling.

const HttpClient = preload("res://addons/ai_pixel_art_generator/api/http_client.gd")
const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

var http_client: HttpClient


func before_each() -> void:
	http_client = HttpClient.new()
	add_child(http_client)


func after_each() -> void:
	if http_client:
		http_client.queue_free()
		http_client = null


## Basic Setup Tests


func test_http_client_initializes() -> void:
	assert_not_null(http_client, "HttpClient should initialize")


func test_http_client_has_timeout_default() -> void:
	assert_gt(http_client.timeout_seconds, 0, "Should have default timeout")


## Request Building Tests


func test_can_set_timeout() -> void:
	http_client.timeout_seconds = 30.0
	assert_eq(http_client.timeout_seconds, 30.0, "Should set timeout")


func test_can_build_headers() -> void:
	var headers := http_client.build_headers({
		"Content-Type": "application/json",
		"x-goog-api-key": "test-key"
	})

	assert_eq(headers.size(), 2, "Should have 2 headers")
	assert_has(headers, "Content-Type: application/json", "Should contain Content-Type")
	assert_has(headers, "x-goog-api-key: test-key", "Should contain API key")


func test_build_headers_with_empty_dict() -> void:
	var headers := http_client.build_headers({})
	assert_eq(headers.size(), 0, "Should have empty headers array")


## Request Validation Tests


func test_validate_url_accepts_https() -> void:
	var result := http_client.validate_url("https://example.com/api")
	assert_true(result.is_ok(), "Should accept HTTPS URL")


func test_validate_url_accepts_http() -> void:
	var result := http_client.validate_url("http://example.com/api")
	assert_true(result.is_ok(), "Should accept HTTP URL")


func test_validate_url_rejects_empty() -> void:
	var result := http_client.validate_url("")
	assert_true(result.is_err(), "Should reject empty URL")
	assert_string_contains(result.error, "empty", "Error should mention empty")


func test_validate_url_rejects_invalid() -> void:
	var result := http_client.validate_url("not-a-url")
	assert_true(result.is_err(), "Should reject invalid URL")


## JSON Body Tests


func test_encode_json_body_success() -> void:
	var data := {"key": "value", "number": 123}
	var result := http_client.encode_json_body(data)

	assert_true(result.is_ok(), "Should encode JSON successfully")
	assert_string_contains(result.value, "key", "JSON should contain key")
	assert_string_contains(result.value, "value", "JSON should contain value")


func test_encode_json_body_with_nested_data() -> void:
	var data := {
		"outer": {
			"inner": "value"
		}
	}
	var result := http_client.encode_json_body(data)
	assert_true(result.is_ok(), "Should encode nested JSON")


func test_encode_json_body_with_array() -> void:
	var data := {
		"items": [1, 2, 3]
	}
	var result := http_client.encode_json_body(data)
	assert_true(result.is_ok(), "Should encode array in JSON")


## Response Parsing Tests


func test_parse_json_response_success() -> void:
	var json_string := '{"status": "ok", "value": 42}'
	var result := http_client.parse_json_response(json_string)

	assert_true(result.is_ok(), "Should parse valid JSON")
	assert_eq(result.value["status"], "ok", "Should extract status")
	assert_eq(result.value["value"], 42, "Should extract number")


func test_parse_json_response_with_invalid_json() -> void:
	var invalid_json := '{"broken": '
	var result := http_client.parse_json_response(invalid_json)

	assert_true(result.is_err(), "Should fail on invalid JSON")
	assert_string_contains(result.error, "parse", "Error should mention parsing")


func test_parse_json_response_with_empty_string() -> void:
	var result := http_client.parse_json_response("")
	assert_true(result.is_err(), "Should fail on empty string")


## HTTP Status Code Handling Tests


func test_is_success_status_code() -> void:
	assert_true(http_client.is_success_status(200), "200 is success")
	assert_true(http_client.is_success_status(201), "201 is success")
	assert_true(http_client.is_success_status(204), "204 is success")


func test_is_not_success_status_code() -> void:
	assert_false(http_client.is_success_status(400), "400 is not success")
	assert_false(http_client.is_success_status(401), "401 is not success")
	assert_false(http_client.is_success_status(404), "404 is not success")
	assert_false(http_client.is_success_status(500), "500 is not success")


func test_get_status_message_for_common_codes() -> void:
	assert_string_contains(http_client.get_status_message(200), "OK", "200 message")
	assert_string_contains(http_client.get_status_message(400), "Bad", "400 message")
	assert_string_contains(http_client.get_status_message(401), "Unauthorized", "401 message")
	assert_string_contains(http_client.get_status_message(404), "Not Found", "404 message")
	assert_string_contains(http_client.get_status_message(500), "Server", "500 message")


## Error Result Building Tests


func test_build_error_result_for_http_status() -> void:
	var result := http_client.build_http_error_result(404, "Not Found")

	assert_true(result.is_err(), "Should be error result")
	assert_string_contains(result.error, "404", "Should include status code")
	assert_string_contains(result.error, "Not Found", "Should include reason")


func test_build_error_result_for_network_error() -> void:
	var result := http_client.build_network_error_result("Connection timeout")

	assert_true(result.is_err(), "Should be error result")
	assert_string_contains(result.error, "timeout", "Should include error message")


# Note: Testing actual HTTP requests requires either:
# 1. A mock HTTP server (complex)
# 2. Real external calls (unreliable for unit tests)
# 3. Integration tests with httpbin.org or similar
#
# We'll test the request/response handling logic here,
# and do integration tests separately if needed.
