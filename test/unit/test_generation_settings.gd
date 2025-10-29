extends GutTest

const GenerationSettings = preload("res://addons/ai_pixel_art_generator/models/generation_settings.gd")

var logger

func before_each() -> void:
	logger = get_logger()

## ============================================================================
## Constructor and Basic Properties
## ============================================================================

func test_generation_settings_creation_with_all_properties() -> void:
	var settings := GenerationSettings.new(0.7, "make it vibrant")

	assert_eq(settings.temperature, 0.7, "Temperature should be set")
	assert_eq(settings.detail_prompt, "make it vibrant", "Detail prompt should be set")

func test_generation_settings_default_constructor() -> void:
	var settings := GenerationSettings.new()

	assert_eq(settings.temperature, 1.0, "Default temperature should be 1.0")
	assert_eq(settings.detail_prompt, "", "Default detail prompt should be empty")

## ============================================================================
## Validation
## ============================================================================

func test_validate_returns_ok_for_valid_settings() -> void:
	var settings := GenerationSettings.new(0.5, "test prompt")

	var result := settings.validate()
	assert_true(result.is_ok(), "Valid settings should pass validation")

func test_validate_fails_for_negative_temperature() -> void:
	var settings := GenerationSettings.new(-0.1, "prompt")

	var result := settings.validate()
	assert_true(result.is_err(), "Negative temperature should fail validation")
	assert_string_contains(result.error, "temperature", "Error should mention temperature")

func test_validate_fails_for_temperature_above_2() -> void:
	var settings := GenerationSettings.new(2.1, "prompt")

	var result := settings.validate()
	assert_true(result.is_err(), "Temperature above 2.0 should fail validation")
	assert_string_contains(result.error, "temperature", "Error should mention temperature")

func test_validate_allows_zero_temperature() -> void:
	var settings := GenerationSettings.new(0.0, "prompt")

	var result := settings.validate()
	assert_true(result.is_ok(), "Temperature of 0.0 should be valid")

func test_validate_allows_temperature_exactly_2() -> void:
	var settings := GenerationSettings.new(2.0, "prompt")

	var result := settings.validate()
	assert_true(result.is_ok(), "Temperature of 2.0 should be valid")

func test_validate_allows_empty_detail_prompt() -> void:
	var settings := GenerationSettings.new(1.0, "")

	var result := settings.validate()
	assert_true(result.is_ok(), "Empty detail prompt should be valid (optional)")

## ============================================================================
## Serialization - to_dict()
## ============================================================================

func test_to_dict_returns_all_properties() -> void:
	var settings := GenerationSettings.new(0.8, "vibrant colors")

	var dict := settings.to_dict()

	assert_eq(dict["temperature"], 0.8, "Dictionary should contain temperature")
	assert_eq(dict["detail_prompt"], "vibrant colors", "Dictionary should contain detail_prompt")

func test_to_dict_with_default_values() -> void:
	var settings := GenerationSettings.new()

	var dict := settings.to_dict()

	assert_eq(dict["temperature"], 1.0, "Default temperature should be in dict")
	assert_eq(dict["detail_prompt"], "", "Default detail_prompt should be in dict")

## ============================================================================
## Deserialization - from_dict()
## ============================================================================

func test_from_dict_creates_settings_with_all_properties() -> void:
	var dict := {
		"temperature": 0.6,
		"detail_prompt": "test detail"
	}

	var result := GenerationSettings.from_dict(dict)

	assert_true(result.is_ok(), "Should successfully create settings from valid data")

	var settings: GenerationSettings = result.value
	assert_eq(settings.temperature, 0.6, "Temperature should match")
	assert_eq(settings.detail_prompt, "test detail", "Detail prompt should match")

func test_from_dict_fails_with_missing_temperature() -> void:
	var dict := {
		"detail_prompt": "test"
	}

	var result := GenerationSettings.from_dict(dict)
	assert_true(result.is_err(), "Should fail without temperature")

func test_from_dict_fails_with_missing_detail_prompt() -> void:
	var dict := {
		"temperature": 1.0
	}

	var result := GenerationSettings.from_dict(dict)
	assert_true(result.is_err(), "Should fail without detail_prompt")

func test_from_dict_handles_invalid_temperature_type() -> void:
	var dict := {
		"temperature": "not_a_number",
		"detail_prompt": "test"
	}

	var result := GenerationSettings.from_dict(dict)
	assert_true(result.is_err(), "Should fail with non-numeric temperature")

## ============================================================================
## Round-trip Serialization
## ============================================================================

func test_roundtrip_serialization() -> void:
	var original := GenerationSettings.new(0.75, "dark and moody")

	var dict := original.to_dict()
	var result := GenerationSettings.from_dict(dict)

	assert_true(result.is_ok(), "Roundtrip should succeed")

	var restored: GenerationSettings = result.value
	assert_eq(restored.temperature, original.temperature, "Temperature should survive roundtrip")
	assert_eq(restored.detail_prompt, original.detail_prompt, "Detail prompt should survive roundtrip")
