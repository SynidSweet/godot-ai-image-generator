class_name GeminiResponseParser

## Gemini Response Parser
##
## Parses JSON responses from Gemini 2.5 Flash Image API.
## Extracts generated images from response candidates and handles errors.
##
## Usage:
##   var parser := GeminiResponseParser.new()
##   var result := parser.parse_response(response_dict)
##   if result.is_ok():
##       var image: Image = result.value

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

var _logger: PluginLogger


func _init() -> void:
	_logger = PluginLogger.get_logger("GeminiResponseParser")


## Parses a Gemini API response and extracts the generated image
##
## Expected response structure:
## {
##   "candidates": [{
##     "content": {
##       "parts": [
##         {"inline_data": {"mime_type": "image/png", "data": "base64..."}}
##       ]
##     }
##   }]
## }
##
## Returns: Result<Image>
func parse_response(response: Dictionary) -> Result:
	# Log the response structure for debugging
	_logger.info("Parsing API response", {
		"has_candidates": response.has("candidates"),
		"has_error": response.has("error"),
		"keys": str(response.keys())
	})

	# Check for API error
	if response.has("error"):
		var error_msg := extract_error_message(response)
		_logger.error("API returned error", {"error": error_msg})
		return Result.err("API error: %s" % error_msg)

	# Validate response structure
	if not response.has("candidates"):
		var error_msg := extract_error_message(response)
		return Result.err("Invalid response: no candidates field. %s" % error_msg)

	var candidates: Array = response["candidates"]
	if candidates.is_empty():
		return Result.err("Invalid response: candidates array is empty")

	# Get first candidate
	var candidate: Dictionary = candidates[0]

	if not candidate.has("content"):
		return Result.err("Invalid response: candidate has no content field")

	var content: Dictionary = candidate["content"]

	if not content.has("parts"):
		return Result.err("Invalid response: content has no parts field")

	var parts: Array = content["parts"]
	if parts.is_empty():
		return Result.err("Invalid response: parts array is empty")

	# Log what we got in parts
	_logger.info("Response parts", {"count": parts.size()})
	for i in range(parts.size()):
		var part = parts[i]
		if part is Dictionary:
			_logger.info("Part %d keys" % i, {"keys": str(part.keys())})

	# Find first image part (check both camelCase and snake_case)
	for part in parts:
		if part is Dictionary and (part.has("inlineData") or part.has("inline_data")):
			var image_result := extract_image_from_part(part)
			if image_result.is_ok():
				_logger.debug("Successfully extracted image from response")
				return image_result
			else:
				_logger.warn("Skipping invalid image part", {"error": image_result.error})

	return Result.err("No valid image found in response parts")


## Extracts an Image from a response part
func extract_image_from_part(part: Dictionary) -> Result:
	# Check for both camelCase (actual API) and snake_case (our tests)
	var inline_data_key := ""
	if part.has("inlineData"):
		inline_data_key = "inlineData"
	elif part.has("inline_data"):
		inline_data_key = "inline_data"
	else:
		return Result.err("Part does not have inlineData or inline_data")

	var inline_data: Dictionary = part[inline_data_key]

	# Check for both camelCase (actual API) and snake_case (our tests)
	var mime_key := ""
	if inline_data.has("mimeType"):
		mime_key = "mimeType"
	elif inline_data.has("mime_type"):
		mime_key = "mime_type"
	else:
		return Result.err("inline_data missing mimeType/mime_type")

	if not inline_data.has("data"):
		return Result.err("inline_data missing data")

	var mime_type: String = inline_data[mime_key]
	var base64_data: String = inline_data["data"]

	# Validate mime type is image
	if not mime_type.begins_with("image/"):
		return Result.err("Invalid mime type: %s (expected image/*)" % mime_type)

	# Decode base64 to image
	return decode_base64_to_image(base64_data)


## Decodes base64 string to Image
func decode_base64_to_image(base64_string: String) -> Result:
	if base64_string.is_empty():
		return Result.err("Cannot decode empty base64 string")

	# Decode base64 to bytes
	var image_bytes := Marshalls.base64_to_raw(base64_string)
	if image_bytes.is_empty():
		return Result.err("Failed to decode base64 string")

	# Load image from bytes
	var image := Image.new()
	var error := image.load_png_from_buffer(image_bytes)

	if error != OK:
		# Try JPEG if PNG fails
		error = image.load_jpg_from_buffer(image_bytes)
		if error != OK:
			return Result.err("Failed to load image from buffer (error code: %d)" % error)

	if image.is_empty():
		return Result.err("Decoded image is empty")

	return Result.ok(image)


## Extracts error message from error response
##
## Expected error structure:
## {
##   "error": {
##     "code": 400,
##     "message": "Error message",
##     "status": "INVALID_ARGUMENT"
##   }
## }
func extract_error_message(response: Dictionary) -> String:
	if not response.has("error"):
		return "Unknown error (no error field in response)"

	var error: Dictionary = response["error"]

	var parts: Array[String] = []

	if error.has("code"):
		parts.append("Code %d" % error["code"])

	if error.has("status"):
		parts.append("Status: %s" % error["status"])

	if error.has("message"):
		parts.append("Message: %s" % error["message"])

	if parts.is_empty():
		return "Unknown error (empty error object)"

	return " | ".join(parts)
