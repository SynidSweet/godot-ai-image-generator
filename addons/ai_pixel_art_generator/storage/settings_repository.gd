## SettingsRepository
##
## Handles plugin settings and API key storage using ConfigFile.
## Settings are stored in user://ai_pixel_art_settings.cfg
##
## Usage:
##   const SettingsRepository = preload("res://addons/ai_pixel_art_generator/storage/settings_repository.gd")
##   var repo := SettingsRepository.new()
##   var result := repo.save_api_key("your-api-key")

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

## Path to settings file
const SETTINGS_FILE: String = "user://ai_pixel_art_settings.cfg"

## Section names in config file
const SECTION_API: String = "api"
const SECTION_PREFERENCES: String = "preferences"

var config: ConfigFile
var logger: PluginLogger

func _init() -> void:
	logger = PluginLogger.get_logger("SettingsRepository")
	config = ConfigFile.new()
	_load_config()

## Saves the Gemini API key
##
## Parameters:
##   api_key: API key to save
##
## Returns:
##   Result: Ok if saved successfully
func save_api_key(api_key: String) -> Result:
	config.set_value(SECTION_API, "gemini_api_key", api_key)
	return _save_config()

## Loads the Gemini API key
##
## Returns:
##   Result<String>: Ok with API key if set, Err if not found
func load_api_key() -> Result:
	if not config.has_section_key(SECTION_API, "gemini_api_key"):
		return Result.err("API key not configured")

	var api_key: String = config.get_value(SECTION_API, "gemini_api_key")
	return Result.ok(api_key)

## Checks if API key is configured
##
## Returns:
##   bool: True if API key exists
func has_api_key() -> bool:
	return config.has_section_key(SECTION_API, "gemini_api_key")

## Saves a general setting
##
## Parameters:
##   key: Setting key
##   value: Setting value (will be converted to string)
##
## Returns:
##   Result: Ok if saved successfully
func save_setting(key: String, value: String) -> Result:
	config.set_value(SECTION_PREFERENCES, key, value)
	return _save_config()

## Loads a general setting
##
## Parameters:
##   key: Setting key to load
##
## Returns:
##   Result<String>: Ok with value if found, Err if not found
func load_setting(key: String) -> Result:
	if not config.has_section_key(SECTION_PREFERENCES, key):
		return Result.err("Setting not found: %s" % key)

	var value: String = config.get_value(SECTION_PREFERENCES, key)
	return Result.ok(value)

## Loads a setting with a default value if not found
##
## Parameters:
##   key: Setting key to load
##   default_value: Value to return if setting not found
##
## Returns:
##   String: Setting value or default
func load_setting_or(key: String, default_value: String) -> String:
	if not config.has_section_key(SECTION_PREFERENCES, key):
		return default_value

	return config.get_value(SECTION_PREFERENCES, key)

## Deletes a setting
##
## Parameters:
##   key: Setting key to delete
##
## Returns:
##   Result: Ok if deleted
func delete_setting(key: String) -> Result:
	if not config.has_section_key(SECTION_PREFERENCES, key):
		return Result.err("Setting not found: %s" % key)

	config.erase_section_key(SECTION_PREFERENCES, key)
	return _save_config()

## Lists all settings
##
## Returns:
##   Result<Dictionary>: Ok with dictionary of all settings
func list_all_settings() -> Result:
	var settings := {}

	if config.has_section(SECTION_PREFERENCES):
		var keys := config.get_section_keys(SECTION_PREFERENCES)
		for key in keys:
			settings[key] = config.get_value(SECTION_PREFERENCES, key)

	return Result.ok(settings)

## Clears all settings including API key
##
## Returns:
##   Result: Ok if cleared
func clear_all_settings() -> Result:
	config.clear()
	return _save_config()

## ============================================================================
## Private Helper Functions
## ============================================================================

func _load_config() -> void:
	var error := config.load(SETTINGS_FILE)

	if error == OK:
		logger.info("Loaded settings", {"path": SETTINGS_FILE})
	elif error == ERR_FILE_NOT_FOUND:
		logger.info("No settings file found, will create on first save")
	else:
		logger.warn("Failed to load settings", {"error": error})

func _save_config() -> Result:
	var error := config.save(SETTINGS_FILE)

	if error != OK:
		return Result.err("Failed to save settings: error %d" % error)

	logger.info("Saved settings", {"path": SETTINGS_FILE})
	return Result.ok(true)
