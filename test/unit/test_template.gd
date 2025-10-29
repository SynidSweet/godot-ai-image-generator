extends GutTest

const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")

# Test fixtures
var valid_template_data: Dictionary
var logger

func before_each() -> void:
	valid_template_data = {
		"id": "test-template-1",
		"name": "Test NPC",
		"reference_image_path": "res://test/fixtures/test_image.png",
		"base_prompt": "A pixel art character",
		"target_resolution": {"x": 32, "y": 32},
		"palette_name": "db32"
	}
	logger = get_logger()

## ============================================================================
## Constructor and Basic Properties
## ============================================================================

func test_template_creation_with_all_properties() -> void:
	var template := Template.new(
		"id-1",
		"My Template",
		"res://image.png",
		"A prompt",
		Vector2i(64, 64),
		"palette1"
	)

	assert_eq(template.id, "id-1", "ID should be set")
	assert_eq(template.name, "My Template", "Name should be set")
	assert_eq(template.reference_image_path, "res://image.png", "Image path should be set")
	assert_eq(template.base_prompt, "A prompt", "Base prompt should be set")
	assert_eq(template.target_resolution, Vector2i(64, 64), "Target resolution should be set")
	assert_eq(template.palette_name, "palette1", "Palette name should be set")

func test_template_default_constructor() -> void:
	var template := Template.new()

	assert_eq(template.id, "", "ID should be empty by default")
	assert_eq(template.name, "", "Name should be empty by default")
	assert_eq(template.reference_image_path, "", "Image path should be empty by default")
	assert_eq(template.base_prompt, "", "Base prompt should be empty by default")
	assert_eq(template.target_resolution, Vector2i(32, 32), "Target resolution should default to 32x32")
	assert_eq(template.palette_name, "", "Palette name should be empty by default")

## ============================================================================
## Validation
## ============================================================================

func test_validate_returns_ok_for_valid_template() -> void:
	var template := Template.new(
		"id-1",
		"Valid Template",
		"res://image.png",
		"A valid prompt",
		Vector2i(64, 64),
		"db32"
	)

	var result := template.validate()
	assert_true(result.is_ok(), "Valid template should pass validation")

func test_validate_fails_for_empty_id() -> void:
	var template := Template.new(
		"",
		"Name",
		"res://image.png",
		"Prompt",
		Vector2i(64, 64),
		"db32"
	)

	var result := template.validate()
	assert_true(result.is_err(), "Empty ID should fail validation")
	assert_string_contains(result.error, "ID", "Error should mention ID")

func test_validate_fails_for_empty_name() -> void:
	var template := Template.new(
		"id-1",
		"",
		"res://image.png",
		"Prompt",
		Vector2i(64, 64),
		"db32"
	)

	var result := template.validate()
	assert_true(result.is_err(), "Empty name should fail validation")
	assert_string_contains(result.error, "name", "Error should mention name")

func test_validate_fails_for_empty_reference_image_path() -> void:
	var template := Template.new(
		"id-1",
		"Name",
		"",
		"Prompt",
		Vector2i(64, 64),
		"db32"
	)

	var result := template.validate()
	assert_true(result.is_err(), "Empty image path should fail validation")
	assert_string_contains(result.error, "reference_image_path", "Error should mention reference_image_path")

func test_validate_fails_for_empty_base_prompt() -> void:
	var template := Template.new(
		"id-1",
		"Name",
		"res://image.png",
		"",
		Vector2i(64, 64),
		"db32"
	)

	var result := template.validate()
	assert_true(result.is_err(), "Empty base prompt should fail validation")
	assert_string_contains(result.error, "base_prompt", "Error should mention base_prompt")

func test_validate_fails_for_zero_target_resolution() -> void:
	var template := Template.new(
		"id-1",
		"Name",
		"res://image.png",
		"Prompt",
		Vector2i(0, 0),
		"db32"
	)

	var result := template.validate()
	assert_true(result.is_err(), "Zero resolution should fail validation")
	assert_string_contains(result.error, "target_resolution", "Error should mention target_resolution")

func test_validate_fails_for_negative_target_resolution() -> void:
	var template := Template.new(
		"id-1",
		"Name",
		"res://image.png",
		"Prompt",
		Vector2i(-32, 32),
		"db32"
	)

	var result := template.validate()
	assert_true(result.is_err(), "Negative resolution should fail validation")

func test_validate_fails_for_empty_palette_name() -> void:
	var template := Template.new(
		"id-1",
		"Name",
		"res://image.png",
		"Prompt",
		Vector2i(64, 64),
		""
	)

	var result := template.validate()
	assert_true(result.is_err(), "Empty palette name should fail validation")
	assert_string_contains(result.error, "palette_name", "Error should mention palette_name")

## ============================================================================
## Serialization - to_dict()
## ============================================================================

func test_to_dict_returns_all_properties() -> void:
	var template := Template.new(
		"id-1",
		"My Template",
		"res://image.png",
		"A prompt",
		Vector2i(64, 64),
		"db32"
	)

	var dict := template.to_dict()

	assert_eq(dict["id"], "id-1", "Dictionary should contain ID")
	assert_eq(dict["name"], "My Template", "Dictionary should contain name")
	assert_eq(dict["reference_image_path"], "res://image.png", "Dictionary should contain image path")
	assert_eq(dict["base_prompt"], "A prompt", "Dictionary should contain base prompt")
	assert_eq(dict["target_resolution"]["x"], 64, "Dictionary should contain resolution x")
	assert_eq(dict["target_resolution"]["y"], 64, "Dictionary should contain resolution y")
	assert_eq(dict["palette_name"], "db32", "Dictionary should contain palette name")

func test_to_dict_with_default_values() -> void:
	var template := Template.new()
	var dict := template.to_dict()

	assert_has(dict, "id", "Dictionary should have ID key")
	assert_has(dict, "name", "Dictionary should have name key")
	assert_has(dict, "target_resolution", "Dictionary should have target_resolution key")

## ============================================================================
## Deserialization - from_dict()
## ============================================================================

func test_from_dict_creates_template_with_all_properties() -> void:
	var result := Template.from_dict(valid_template_data)

	assert_true(result.is_ok(), "Should successfully create template from valid data")

	var template: Template = result.value
	assert_eq(template.id, "test-template-1", "ID should match")
	assert_eq(template.name, "Test NPC", "Name should match")
	assert_eq(template.reference_image_path, "res://test/fixtures/test_image.png", "Image path should match")
	assert_eq(template.base_prompt, "A pixel art character", "Base prompt should match")
	assert_eq(template.target_resolution, Vector2i(32, 32), "Target resolution should match")
	assert_eq(template.palette_name, "db32", "Palette name should match")

func test_from_dict_fails_with_missing_id() -> void:
	var data := valid_template_data.duplicate()
	data.erase("id")

	var result := Template.from_dict(data)
	assert_true(result.is_err(), "Should fail without ID")
	assert_string_contains(result.error, "id", "Error should mention missing ID")

func test_from_dict_fails_with_missing_name() -> void:
	var data := valid_template_data.duplicate()
	data.erase("name")

	var result := Template.from_dict(data)
	assert_true(result.is_err(), "Should fail without name")

func test_from_dict_fails_with_missing_target_resolution() -> void:
	var data := valid_template_data.duplicate()
	data.erase("target_resolution")

	var result := Template.from_dict(data)
	assert_true(result.is_err(), "Should fail without target_resolution")

func test_from_dict_handles_invalid_resolution_format() -> void:
	var data := valid_template_data.duplicate()
	data["target_resolution"] = "invalid"

	var result := Template.from_dict(data)
	assert_true(result.is_err(), "Should fail with invalid resolution format")

## ============================================================================
## Round-trip Serialization
## ============================================================================

func test_roundtrip_serialization() -> void:
	var original := Template.new(
		"id-roundtrip",
		"Roundtrip Test",
		"res://test.png",
		"Test prompt",
		Vector2i(128, 128),
		"aap64"
	)

	var dict := original.to_dict()
	var result := Template.from_dict(dict)

	assert_true(result.is_ok(), "Roundtrip should succeed")

	var restored: Template = result.value
	assert_eq(restored.id, original.id, "ID should survive roundtrip")
	assert_eq(restored.name, original.name, "Name should survive roundtrip")
	assert_eq(restored.reference_image_path, original.reference_image_path, "Image path should survive roundtrip")
	assert_eq(restored.base_prompt, original.base_prompt, "Base prompt should survive roundtrip")
	assert_eq(restored.target_resolution, original.target_resolution, "Resolution should survive roundtrip")
	assert_eq(restored.palette_name, original.palette_name, "Palette name should survive roundtrip")
