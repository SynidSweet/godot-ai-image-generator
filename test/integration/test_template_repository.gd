extends GutTest

const TemplateRepository = preload("res://addons/ai_pixel_art_generator/storage/template_repository.gd")
const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")

var repository: TemplateRepository
var test_dir: String
var logger

func before_each() -> void:
	logger = get_logger()
	# Use a unique temporary directory for each test
	test_dir = "user://test_templates_%d/" % Time.get_ticks_msec()
	repository = TemplateRepository.new(test_dir)

func after_each() -> void:
	# Clean up test directory
	_remove_directory_recursive(test_dir)

func _remove_directory_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(path)

## ============================================================================
## Save Template
## ============================================================================

func test_save_template_creates_file() -> void:
	var template := Template.new(
		"test-1",
		"Test Template",
		"res://test.png",
		"A test prompt",
		Vector2i(32, 32),
		"db32"
	)

	var result := repository.save_template(template)

	assert_true(result.is_ok(), "Should successfully save template")

	# Verify file exists
	var file_path := test_dir + "test-1.json"
	assert_true(FileAccess.file_exists(file_path), "Template file should exist")

func test_save_template_returns_error_for_invalid_template() -> void:
	var invalid_template := Template.new("", "", "", "", Vector2i(0, 0), "")

	var result := repository.save_template(invalid_template)

	assert_true(result.is_err(), "Should fail with invalid template")

func test_save_template_overwrites_existing() -> void:
	var template1 := Template.new("test-1", "First", "res://1.png", "Prompt 1", Vector2i(32, 32), "db32")
	var template2 := Template.new("test-1", "Second", "res://2.png", "Prompt 2", Vector2i(64, 64), "aap64")

	repository.save_template(template1)
	var result := repository.save_template(template2)

	assert_true(result.is_ok(), "Should overwrite existing template")

	# Verify the second version is saved
	var load_result := repository.load_template("test-1")
	assert_true(load_result.is_ok(), "Should load template")
	var loaded: Template = load_result.value
	assert_eq(loaded.name, "Second", "Should have updated name")

## ============================================================================
## Load Template
## ============================================================================

func test_load_template_reads_saved_template() -> void:
	var original := Template.new(
		"load-test",
		"Load Test",
		"res://load.png",
		"Load prompt",
		Vector2i(48, 48),
		"grayscale"
	)

	repository.save_template(original)
	var result := repository.load_template("load-test")

	assert_true(result.is_ok(), "Should successfully load template")
	var loaded: Template = result.value
	assert_eq(loaded.id, original.id, "ID should match")
	assert_eq(loaded.name, original.name, "Name should match")
	assert_eq(loaded.base_prompt, original.base_prompt, "Base prompt should match")
	assert_eq(loaded.target_resolution, original.target_resolution, "Resolution should match")

func test_load_template_returns_error_for_nonexistent() -> void:
	var result := repository.load_template("nonexistent")

	assert_true(result.is_err(), "Should fail for nonexistent template")
	assert_string_contains(result.error, "not found", "Error should mention not found")

func test_load_template_handles_corrupted_json() -> void:
	# Create a corrupted JSON file
	DirAccess.make_dir_absolute(test_dir)
	var file_path := test_dir + "corrupted.json"
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string("{invalid json content")
	file.close()

	var result := repository.load_template("corrupted")

	assert_true(result.is_err(), "Should fail with corrupted JSON")

## ============================================================================
## Load All Templates
## ============================================================================

func test_load_all_templates_returns_empty_array_when_none_exist() -> void:
	var result := repository.load_all_templates()

	assert_true(result.is_ok(), "Should succeed even with no templates")
	var templates: Array = result.value
	assert_eq(templates.size(), 0, "Should return empty array")

func test_load_all_templates_returns_all_saved_templates() -> void:
	var template1 := Template.new("t1", "Template 1", "res://1.png", "Prompt 1", Vector2i(32, 32), "db32")
	var template2 := Template.new("t2", "Template 2", "res://2.png", "Prompt 2", Vector2i(64, 64), "aap64")
	var template3 := Template.new("t3", "Template 3", "res://3.png", "Prompt 3", Vector2i(16, 16), "grayscale")

	repository.save_template(template1)
	repository.save_template(template2)
	repository.save_template(template3)

	var result := repository.load_all_templates()

	assert_true(result.is_ok(), "Should successfully load all templates")
	var templates: Array = result.value
	assert_eq(templates.size(), 3, "Should load 3 templates")

func test_load_all_templates_skips_invalid_files() -> void:
	# Save one valid template
	var valid_template := Template.new("valid", "Valid", "res://v.png", "Prompt", Vector2i(32, 32), "db32")
	repository.save_template(valid_template)

	# Create an invalid JSON file
	DirAccess.make_dir_absolute(test_dir)
	var invalid_file := FileAccess.open(test_dir + "invalid.json", FileAccess.WRITE)
	invalid_file.store_string("{bad json")
	invalid_file.close()

	var result := repository.load_all_templates()

	assert_true(result.is_ok(), "Should succeed and skip invalid files")
	var templates: Array = result.value
	assert_eq(templates.size(), 1, "Should only load the valid template")

## ============================================================================
## Delete Template
## ============================================================================

func test_delete_template_removes_file() -> void:
	var template := Template.new("delete-me", "Delete Test", "res://d.png", "Prompt", Vector2i(32, 32), "db32")
	repository.save_template(template)

	var result := repository.delete_template("delete-me")

	assert_true(result.is_ok(), "Should successfully delete template")

	# Verify file no longer exists
	var file_path := test_dir + "delete-me.json"
	assert_false(FileAccess.file_exists(file_path), "Template file should not exist")

func test_delete_template_returns_error_for_nonexistent() -> void:
	var result := repository.delete_template("nonexistent")

	assert_true(result.is_err(), "Should fail for nonexistent template")

func test_delete_template_allows_recreating_with_same_id() -> void:
	var template1 := Template.new("reuse-id", "First", "res://1.png", "Prompt 1", Vector2i(32, 32), "db32")
	repository.save_template(template1)
	repository.delete_template("reuse-id")

	var template2 := Template.new("reuse-id", "Second", "res://2.png", "Prompt 2", Vector2i(64, 64), "aap64")
	var result := repository.save_template(template2)

	assert_true(result.is_ok(), "Should allow reusing deleted ID")

## ============================================================================
## Template Exists
## ============================================================================

func test_template_exists_returns_true_for_existing() -> void:
	var template := Template.new("exists-test", "Exists", "res://e.png", "Prompt", Vector2i(32, 32), "db32")
	repository.save_template(template)

	var exists := repository.template_exists("exists-test")

	assert_true(exists, "Should return true for existing template")

func test_template_exists_returns_false_for_nonexistent() -> void:
	var exists := repository.template_exists("nonexistent")

	assert_false(exists, "Should return false for nonexistent template")

## ============================================================================
## Directory Creation
## ============================================================================

func test_repository_creates_directory_if_not_exists() -> void:
	var new_dir := "user://auto_create_test_%d/" % Time.get_ticks_msec()
	var new_repo := TemplateRepository.new(new_dir)

	var template := Template.new("auto", "Auto", "res://a.png", "Prompt", Vector2i(32, 32), "db32")
	var result := new_repo.save_template(template)

	assert_true(result.is_ok(), "Should create directory and save")
	assert_true(DirAccess.dir_exists_absolute(new_dir), "Directory should be created")

	# Cleanup
	_remove_directory_recursive(new_dir)
