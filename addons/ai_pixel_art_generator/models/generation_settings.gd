## GenerationSettings Model
##
## Holds configuration parameters for AI image generation.
## Controls aspects like randomness (temperature) and additional prompt details.
##
## Usage:
##   const GenerationSettings = preload("res://addons/ai_pixel_art_generator/models/generation_settings.gd")
##   var settings := GenerationSettings.new(0.8, "vibrant colors, high contrast")
##   var validation := settings.validate()

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

## Temperature parameter for AI generation (0.0 to 2.0)
## Higher values = more random/creative, lower values = more deterministic
var temperature: float = 1.0

## Additional prompt details to refine the generation
var detail_prompt: String = ""

## Constructor
##
## Parameters:
##   p_temperature: AI temperature setting (0.0 to 2.0, default 1.0)
##   p_detail_prompt: Additional prompt text (default empty)
func _init(p_temperature: float = 1.0, p_detail_prompt: String = "") -> void:
	temperature = p_temperature
	detail_prompt = p_detail_prompt

## Validates that settings are within acceptable ranges
##
## Returns:
##   Result: Ok if valid, Err with error message if invalid
func validate() -> Result:
	if temperature < 0.0 or temperature > 2.0:
		return Result.err("temperature must be between 0.0 and 2.0 (got %.2f)" % temperature)

	return Result.ok(true)

## Serializes the settings to a dictionary
##
## Returns:
##   Dictionary: Settings data
func to_dict() -> Dictionary:
	return {
		"temperature": temperature,
		"detail_prompt": detail_prompt
	}

## Creates GenerationSettings from a dictionary
##
## Parameters:
##   dict: Dictionary containing settings data
##
## Returns:
##   Result<GenerationSettings>: Ok with settings if successful, Err if invalid
static func from_dict(dict: Dictionary) -> Result:
	# Validate required keys
	if not dict.has("temperature"):
		return Result.err("GenerationSettings dictionary missing required key 'temperature'")

	if not dict.has("detail_prompt"):
		return Result.err("GenerationSettings dictionary missing required key 'detail_prompt'")

	# Validate temperature type
	var temp_value = dict["temperature"]
	if not (temp_value is float or temp_value is int):
		return Result.err("GenerationSettings temperature must be a number")

	# Validate detail_prompt type
	var prompt_value = dict["detail_prompt"]
	if not prompt_value is String:
		return Result.err("GenerationSettings detail_prompt must be a string")

	# Create settings (load current script to instantiate)
	var SettingsScript = load("res://addons/ai_pixel_art_generator/models/generation_settings.gd")
	var settings = SettingsScript.new(float(temp_value), prompt_value)

	return Result.ok(settings)
