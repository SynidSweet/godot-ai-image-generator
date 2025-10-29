extends Node
class_name HttpClient

## HTTP Client Wrapper
##
## A thin wrapper around Godot's HTTPRequest providing:
## - Cleaner async interface with signals
## - Result<T> error handling
## - JSON encoding/decoding utilities
## - HTTP status code handling
##
## Usage:
##   var client := HttpClient.new()
##   add_child(client)
##   client.request_completed.connect(_on_request_completed)
##   client.post_json(url, headers, body_dict)

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

## Signal emitted when request completes (success or failure)
signal request_completed(result: Result)

## Timeout for HTTP requests in seconds
var timeout_seconds: float = 30.0

var _http_request: HTTPRequest
var _logger: PluginLogger


func _init() -> void:
	_logger = PluginLogger.get_logger("HttpClient")


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.timeout = timeout_seconds
	add_child(_http_request)
	_http_request.request_completed.connect(_on_http_request_completed)


## Performs a POST request with JSON body
##
## Returns immediately. Connect to request_completed signal for result.
func post_json(url: String, headers_dict: Dictionary, body_dict: Dictionary) -> void:
	var url_validation := validate_url(url)
	if url_validation.is_err():
		_emit_error_result(url_validation.error)
		return

	var json_result := encode_json_body(body_dict)
	if json_result.is_err():
		_emit_error_result(json_result.error)
		return

	var headers := build_headers(headers_dict)
	headers.append("Content-Type: application/json")

	_logger.debug("POST request", {"url": url, "body_size": len(json_result.value)})

	var error := _http_request.request(url, headers, HTTPClient.METHOD_POST, json_result.value)
	if error != OK:
		_emit_error_result("Failed to send HTTP request: error code %d" % error)


## Validates a URL string
func validate_url(url: String) -> Result:
	if url.is_empty():
		return Result.err("URL cannot be empty")

	if not (url.begins_with("http://") or url.begins_with("https://")):
		return Result.err("URL must start with http:// or https://")

	return Result.ok(url)


## Builds headers array from dictionary
##
## Converts {"Key": "value"} to ["Key: value"]
func build_headers(headers_dict: Dictionary) -> Array[String]:
	var headers: Array[String] = []
	for key in headers_dict.keys():
		headers.append("%s: %s" % [key, headers_dict[key]])
	return headers


## Encodes a dictionary as JSON string
func encode_json_body(body_dict: Dictionary) -> Result:
	var json := JSON.stringify(body_dict)
	if json.is_empty():
		return Result.err("Failed to encode JSON body")
	return Result.ok(json)


## Parses a JSON response string into a dictionary
func parse_json_response(json_string: String) -> Result:
	if json_string.is_empty():
		return Result.err("Cannot parse empty JSON string")

	var json := JSON.new()
	var error := json.parse(json_string)

	if error != OK:
		return Result.err("Failed to parse JSON: %s at line %d" % [
			json.get_error_message(),
			json.get_error_line()
		])

	return Result.ok(json.data)


## Checks if HTTP status code represents success (2xx)
func is_success_status(status_code: int) -> bool:
	return status_code >= 200 and status_code < 300


## Gets a human-readable message for HTTP status code
func get_status_message(status_code: int) -> String:
	match status_code:
		200: return "OK"
		201: return "Created"
		204: return "No Content"
		400: return "Bad Request"
		401: return "Unauthorized"
		403: return "Forbidden"
		404: return "Not Found"
		429: return "Too Many Requests"
		500: return "Internal Server Error"
		502: return "Bad Gateway"
		503: return "Service Unavailable"
		_: return "HTTP %d" % status_code


## Builds an error Result for HTTP status errors
func build_http_error_result(status_code: int, response_body: String = "") -> Result:
	var message := "HTTP error %d: %s" % [status_code, get_status_message(status_code)]
	if not response_body.is_empty():
		message += "\nResponse: %s" % response_body
	return Result.err(message)


## Builds an error Result for network errors
func build_network_error_result(error_message: String) -> Result:
	return Result.err("Network error: %s" % error_message)


## Internal callback when HTTPRequest completes
func _on_http_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	# Check for network/request errors
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg := _get_request_error_message(result)
		_logger.error("HTTP request failed", {"error": error_msg, "code": result})
		request_completed.emit(build_network_error_result(error_msg))
		return

	# Check HTTP status code
	if not is_success_status(response_code):
		var body_string := body.get_string_from_utf8()
		_logger.warn("HTTP error response", {
			"status": response_code,
			"body_size": len(body_string)
		})
		request_completed.emit(build_http_error_result(response_code, body_string))
		return

	# Success - parse body
	var body_string := body.get_string_from_utf8()
	var parse_result := parse_json_response(body_string)

	if parse_result.is_err():
		_logger.error("Failed to parse response JSON", {"error": parse_result.error})
		request_completed.emit(parse_result)
		return

	_logger.debug("HTTP request succeeded", {"status": response_code})
	request_completed.emit(Result.ok(parse_result.value))


## Emits an error result immediately
func _emit_error_result(error_message: String) -> void:
	_logger.error("Request validation failed", {"error": error_message})
	request_completed.emit(Result.err(error_message))


## Converts HTTPRequest result code to human-readable message
func _get_request_error_message(result_code: int) -> String:
	match result_code:
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "Chunked body size mismatch"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "Cannot connect to host"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Cannot resolve hostname"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Connection error"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS handshake error"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "No response from server"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "Response body size limit exceeded"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "Request failed"
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return "Cannot open download file"
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "Download file write error"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "Redirect limit reached"
		HTTPRequest.RESULT_TIMEOUT:
			return "Request timeout"
		_:
			return "Unknown error (code: %d)" % result_code
