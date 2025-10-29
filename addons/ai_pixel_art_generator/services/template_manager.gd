extends Node
class_name TemplateManager

## Template Manager Service
##
## Business logic layer for template management. Provides CRUD operations
## with validation and emits signals for UI reactivity.
##
## Usage:
##   var manager := TemplateManager.new()
##   add_child(manager)
##   manager.template_created.connect(_on_template_created)
##   var result := manager.create_template(...)

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")
const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
const TemplateRepository = preload("res://addons/ai_pixel_art_generator/storage/template_repository.gd")

## Emitted when a template is created
signal template_created(template)

## Emitted when a template is updated
signal template_updated(template)

## Emitted when a template is deleted
signal template_deleted(template_id)

var _repository: TemplateRepository
var _logger: PluginLogger


## Constructor
##
## Parameters:
##   storage_dir: Directory for template storage (for testing)
func _init(storage_dir: String = "user://templates/") -> void:
	_repository = TemplateRepository.new(storage_dir)
	_logger = PluginLogger.get_logger("TemplateManager")


## Creates a new template
##
## Parameters:
##   id: Unique identifier
##   name: Display name
##   reference_image_path: Path to reference image
##   base_prompt: Generation prompt
##   target_resolution: Target pixel art size
##   palette_name: Palette to use
##
## Returns:
##   Result<Template>: Created template or error
func create_template(
	id: String,
	name: String,
	reference_image_path: String,
	base_prompt: String,
	target_resolution: Vector2i,
	palette_name: String
) -> Result:
	# Create template object
	var template := Template.new(
		id,
		name,
		reference_image_path,
		base_prompt,
		target_resolution,
		palette_name
	)

	# Validate
	var validation := template.validate()
	if validation.is_err():
		return Result.err("Invalid template: %s" % validation.error)

	# Check if ID already exists
	if template_exists(id):
		return Result.err("Template with ID '%s' already exists" % id)

	# Save to repository
	var save_result := _repository.save_template(template)
	if save_result.is_err():
		return Result.err("Failed to save template: %s" % save_result.error)

	_logger.info("Template created", {"id": id, "name": name})
	template_created.emit(template)

	return Result.ok(template)


## Gets a template by ID
##
## Parameters:
##   id: Template ID
##
## Returns:
##   Result<Template>: Template if found, error otherwise
func get_template(id: String) -> Result:
	if id.is_empty():
		return Result.err("Template ID cannot be empty")

	var result := _repository.load_template(id)
	if result.is_err():
		return Result.err("Template '%s' not found" % id)

	return result


## Updates an existing template
##
## Parameters:
##   template: Template to update
##
## Returns:
##   Result: Ok if updated, Err if failed
func update_template(template: Template) -> Result:
	if template == null:
		return Result.err("Template cannot be null")

	# Validate
	var validation := template.validate()
	if validation.is_err():
		return Result.err("Invalid template: %s" % validation.error)

	# Check if exists
	if not template_exists(template.id):
		return Result.err("Template '%s' does not exist" % template.id)

	# Save to repository
	var save_result := _repository.save_template(template)
	if save_result.is_err():
		return Result.err("Failed to update template: %s" % save_result.error)

	_logger.info("Template updated", {"id": template.id})
	template_updated.emit(template)

	return Result.ok(template)


## Deletes a template
##
## Parameters:
##   id: Template ID to delete
##
## Returns:
##   Result: Ok if deleted, Err if failed
func delete_template(id: String) -> Result:
	if id.is_empty():
		return Result.err("Template ID cannot be empty")

	# Check if exists
	if not template_exists(id):
		return Result.err("Template '%s' does not exist" % id)

	# Delete from repository
	var delete_result := _repository.delete_template(id)
	if delete_result.is_err():
		return Result.err("Failed to delete template: %s" % delete_result.error)

	_logger.info("Template deleted", {"id": id})
	template_deleted.emit(id)

	return Result.ok(true)


## Lists all templates
##
## Returns:
##   Result<Array[Template]>: Array of templates or error
func list_templates() -> Result:
	return _repository.load_all_templates()


## Checks if a template exists
##
## Parameters:
##   id: Template ID
##
## Returns:
##   bool: True if exists, false otherwise
func template_exists(id: String) -> bool:
	return _repository.template_exists(id)


## Gets the number of templates
##
## Returns:
##   int: Number of templates
func get_template_count() -> int:
	var result := list_templates()
	if result.is_ok():
		return result.value.size()
	return 0
