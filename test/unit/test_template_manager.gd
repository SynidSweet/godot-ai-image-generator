extends GutTest

## Tests for TemplateManager
##
## TemplateManager provides business logic layer for template operations.
## It wraps TemplateRepository and adds validation, signals, and convenience methods.

const TemplateManager = preload("res://addons/ai_pixel_art_generator/services/template_manager.gd")
const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

var manager: TemplateManager
var test_dir: String


func before_each() -> void:
	# Create unique test directory
	test_dir = "user://test_template_manager_%d/" % Time.get_ticks_msec()
	manager = TemplateManager.new(test_dir)


func after_each() -> void:
	# Cleanup
	if manager:
		manager.queue_free()
		manager = null
	_remove_directory_recursive(test_dir)


## Initialization Tests


func test_manager_initializes() -> void:
	assert_not_null(manager, "Manager should initialize")


func test_manager_starts_empty() -> void:
	var result := manager.list_templates()
	assert_true(result.is_ok(), "Should list templates")
	assert_eq(result.value.size(), 0, "Should start empty")


## Create Template Tests


func test_create_template() -> void:
	var result := manager.create_template(
		"test-1",
		"Test Template",
		"res://test.png",
		"A test prompt",
		Vector2i(32, 32),
		"db32"
	)

	assert_true(result.is_ok(), "Should create template")
	assert_not_null(result.value, "Should return template")
	assert_true(result.value is Template, "Should be Template type")
	assert_eq(result.value.id, "test-1", "Should have correct ID")


func test_create_validates_inputs() -> void:
	var result := manager.create_template("", "", "", "", Vector2i.ZERO, "")
	assert_true(result.is_err(), "Should reject invalid inputs")


func test_create_saves_to_repository() -> void:
	var _create_result := manager.create_template(
		"test-1",
		"Test",
		"res://test.png",
		"prompt",
		Vector2i(32, 32),
		"db32"
	)

	# Should be able to load it
	var load_result := manager.get_template("test-1")
	assert_true(load_result.is_ok(), "Should load created template")


## Get Template Tests


func test_get_template_returns_existing() -> void:
	var _create := manager.create_template(
		"test-1",
		"Test",
		"res://test.png",
		"prompt",
		Vector2i(32, 32),
		"db32"
	)

	var result := manager.get_template("test-1")
	assert_true(result.is_ok(), "Should get template")
	assert_eq(result.value.id, "test-1", "Should have correct ID")


func test_get_template_returns_error_for_nonexistent() -> void:
	var result := manager.get_template("nonexistent")
	assert_true(result.is_err(), "Should return error")
	assert_string_contains(result.error, "not found", "Error should mention not found")


## Update Template Tests


func test_update_template() -> void:
	# Create initial template
	var create_result := manager.create_template(
		"test-1",
		"Original Name",
		"res://test.png",
		"prompt",
		Vector2i(32, 32),
		"db32"
	)
	assert_true(create_result.is_ok(), "Should create template")

	var template: Template = create_result.value
	template.name = "Updated Name"

	var update_result := manager.update_template(template)
	assert_true(update_result.is_ok(), "Should update template")

	# Verify update persisted
	var get_result := manager.get_template("test-1")
	assert_eq(get_result.value.name, "Updated Name", "Name should be updated")


func test_update_validates_template() -> void:
	# Create valid template first
	var _create := manager.create_template(
		"test-1",
		"Test",
		"res://test.png",
		"prompt",
		Vector2i(32, 32),
		"db32"
	)

	# Try to update with invalid data
	var template := Template.new("test-1", "", "", "", Vector2i.ZERO, "")
	var result := manager.update_template(template)
	assert_true(result.is_err(), "Should reject invalid template")


func test_update_nonexistent_template_fails() -> void:
	var template := Template.new(
		"nonexistent",
		"Test",
		"res://test.png",
		"prompt",
		Vector2i(32, 32),
		"db32"
	)

	var result := manager.update_template(template)
	assert_true(result.is_err(), "Should fail to update nonexistent")


## Delete Template Tests


func test_delete_template() -> void:
	# Create template
	var _create := manager.create_template(
		"test-1",
		"Test",
		"res://test.png",
		"prompt",
		Vector2i(32, 32),
		"db32"
	)

	# Delete it
	var result := manager.delete_template("test-1")
	assert_true(result.is_ok(), "Should delete template")

	# Verify it's gone
	var get_result := manager.get_template("test-1")
	assert_true(get_result.is_err(), "Template should be deleted")


func test_delete_nonexistent_template_fails() -> void:
	var result := manager.delete_template("nonexistent")
	assert_true(result.is_err(), "Should fail to delete nonexistent")


## List Templates Tests


func test_list_templates_empty() -> void:
	var result := manager.list_templates()
	assert_true(result.is_ok(), "Should list templates")
	assert_eq(result.value.size(), 0, "Should be empty")


func test_list_templates_returns_all() -> void:
	# Create multiple templates
	var _t1 := manager.create_template("t1", "T1", "res://1.png", "p1", Vector2i(32, 32), "db32")
	var _t2 := manager.create_template("t2", "T2", "res://2.png", "p2", Vector2i(32, 32), "db32")
	var _t3 := manager.create_template("t3", "T3", "res://3.png", "p3", Vector2i(32, 32), "db32")

	var result := manager.list_templates()
	assert_true(result.is_ok(), "Should list templates")
	assert_eq(result.value.size(), 3, "Should have 3 templates")


## Template Existence Tests


func test_template_exists() -> void:
	var _create := manager.create_template(
		"test-1",
		"Test",
		"res://test.png",
		"prompt",
		Vector2i(32, 32),
		"db32"
	)

	assert_true(manager.template_exists("test-1"), "Should exist")
	assert_false(manager.template_exists("nonexistent"), "Should not exist")


## Helper Functions


func _remove_directory_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				_remove_directory_recursive(path.path_join(file_name))
			else:
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(path)
