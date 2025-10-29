extends GutTest

const SettingsRepository = preload("res://addons/ai_pixel_art_generator/storage/settings_repository.gd")

var repository: SettingsRepository
var logger

func before_each() -> void:
	logger = get_logger()
	repository = SettingsRepository.new()
	# Clear any existing settings
	repository.clear_all_settings()

func after_each() -> void:
	# Clean up after tests
	repository.clear_all_settings()

## ============================================================================
## API Key Storage
## ============================================================================

func test_save_api_key() -> void:
	var result := repository.save_api_key("test-api-key-12345")

	assert_true(result.is_ok(), "Should successfully save API key")

func test_load_api_key() -> void:
	repository.save_api_key("my-secret-key")

	var result := repository.load_api_key()

	assert_true(result.is_ok(), "Should load API key")
	assert_eq(result.value, "my-secret-key", "API key should match")

func test_load_api_key_returns_error_when_not_set() -> void:
	var result := repository.load_api_key()

	assert_true(result.is_err(), "Should fail when API key not set")

func test_api_key_persists_across_instances() -> void:
	repository.save_api_key("persistent-key")

	# Create new instance
	var new_repo := SettingsRepository.new()
	var result := new_repo.load_api_key()

	assert_true(result.is_ok(), "API key should persist")
	assert_eq(result.value, "persistent-key", "Key should match")

func test_has_api_key_returns_true_when_set() -> void:
	repository.save_api_key("some-key")

	assert_true(repository.has_api_key(), "Should return true when API key is set")

func test_has_api_key_returns_false_when_not_set() -> void:
	assert_false(repository.has_api_key(), "Should return false when no API key")

## ============================================================================
## General Settings
## ============================================================================

func test_save_setting() -> void:
	var result := repository.save_setting("default_palette", "db32")

	assert_true(result.is_ok(), "Should save setting")

func test_load_setting() -> void:
	repository.save_setting("temperature", "0.8")

	var result := repository.load_setting("temperature")

	assert_true(result.is_ok(), "Should load setting")
	assert_eq(result.value, "0.8", "Setting value should match")

func test_load_setting_with_default() -> void:
	var value := repository.load_setting_or("nonexistent", "default_value")

	assert_eq(value, "default_value", "Should return default for nonexistent setting")

func test_load_existing_setting_with_default() -> void:
	repository.save_setting("existing", "actual_value")

	var value := repository.load_setting_or("existing", "default_value")

	assert_eq(value, "actual_value", "Should return actual value, not default")

func test_delete_setting() -> void:
	repository.save_setting("to_delete", "value")

	var result := repository.delete_setting("to_delete")

	assert_true(result.is_ok(), "Should delete setting")

	var load_result := repository.load_setting("to_delete")
	assert_true(load_result.is_err(), "Deleted setting should not be loadable")

func test_list_all_settings() -> void:
	repository.save_setting("setting1", "value1")
	repository.save_setting("setting2", "value2")
	repository.save_setting("setting3", "value3")

	var result := repository.list_all_settings()

	assert_true(result.is_ok(), "Should list settings")
	var settings: Dictionary = result.value
	assert_eq(settings.size(), 3, "Should have 3 settings")
	assert_has(settings, "setting1", "Should contain setting1")
	assert_has(settings, "setting2", "Should contain setting2")

## ============================================================================
## Clear Settings
## ============================================================================

func test_clear_all_settings() -> void:
	repository.save_setting("test1", "value1")
	repository.save_setting("test2", "value2")
	repository.save_api_key("api-key")

	var result := repository.clear_all_settings()

	assert_true(result.is_ok(), "Should clear all settings")
	assert_false(repository.has_api_key(), "API key should be cleared")

	var load_result := repository.load_setting("test1")
	assert_true(load_result.is_err(), "Settings should be cleared")
