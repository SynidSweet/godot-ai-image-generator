## TemplateRepository
##
## Handles persistence of Template objects to/from JSON files.
## Uses the user:// directory for storing template data.
##
## Usage:
##   const TemplateRepository = preload("res://addons/ai_pixel_art_generator/storage/template_repository.gd")
##   var repo := TemplateRepository.new()
##   var result := repo.save_template(template)

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

## Directory where templates are stored
var storage_dir: String

## Logger instance
var logger: PluginLogger

## Constructor
##
## Parameters:
##   dir: Directory path for storing templates (default: user://templates/)
func _init(dir: String = "user://templates/") -> void:
	storage_dir = dir
	logger = PluginLogger.get_logger("TemplateRepository")
	_ensure_directory_exists()

## Saves a template to disk
##
## Parameters:
##   template: Template to save
##
## Returns:
##   Result: Ok if saved successfully, Err if failed
func save_template(template: Template) -> Result:
	# Validate template first
	var validation := template.validate()
	if validation.is_err():
		return Result.err("Cannot save invalid template: " + validation.error)

	# Ensure directory exists
	_ensure_directory_exists()

	# Serialize template to JSON
	var template_dict := template.to_dict()
	var json_string := JSON.stringify(template_dict, "\t")

	# Write to file
	var file_path := _get_template_path(template.id)
	var file := FileAccess.open(file_path, FileAccess.WRITE)

	if file == null:
		var error := FileAccess.get_open_error()
		return Result.err("Failed to open file for writing: %s (error %d)" % [file_path, error])

	file.store_string(json_string)
	file.close()

	logger.info("Saved template", {"id": template.id, "path": file_path})
	return Result.ok(true)

## Loads a template from disk
##
## Parameters:
##   id: Template ID to load
##
## Returns:
##   Result<Template>: Ok with template if found, Err if not found or invalid
func load_template(id: String) -> Result:
	var file_path := _get_template_path(id)

	# Check if file exists
	if not FileAccess.file_exists(file_path):
		return Result.err("Template not found: %s" % id)

	# Read file
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error := FileAccess.get_open_error()
		return Result.err("Failed to open template file: %s (error %d)" % [file_path, error])

	var json_string := file.get_as_text()
	file.close()

	# Parse JSON
	var json := JSON.new()
	var parse_error := json.parse(json_string)

	if parse_error != OK:
		return Result.err("Failed to parse template JSON: %s (error at line %d)" % [id, json.get_error_line()])

	var data = json.get_data()
	if not data is Dictionary:
		return Result.err("Template JSON is not a dictionary: %s" % id)

	# Deserialize template
	var template_result := Template.from_dict(data)
	if template_result.is_err():
		return Result.err("Failed to deserialize template: " + template_result.error)

	logger.info("Loaded template", {"id": id})
	return template_result

## Loads all templates from disk
##
## Returns:
##   Result<Array>: Ok with array of templates, Err if directory cannot be accessed
func load_all_templates() -> Result:
	_ensure_directory_exists()

	var dir := DirAccess.open(storage_dir)
	if dir == null:
		return Result.err("Failed to open templates directory: " + storage_dir)

	var templates: Array = []

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			# Extract template ID from filename (remove .json extension)
			var template_id := file_name.get_basename()

			# Try to load template
			var load_result := load_template(template_id)
			if load_result.is_ok():
				templates.append(load_result.value)
			else:
				# Log error but continue loading other templates
				logger.warn("Skipping invalid template file", {"file": file_name, "error": load_result.error})

		file_name = dir.get_next()

	dir.list_dir_end()

	logger.info("Loaded templates", {"count": templates.size()})
	return Result.ok(templates)

## Deletes a template from disk
##
## Parameters:
##   id: Template ID to delete
##
## Returns:
##   Result: Ok if deleted successfully, Err if not found or failed
func delete_template(id: String) -> Result:
	var file_path := _get_template_path(id)

	if not FileAccess.file_exists(file_path):
		return Result.err("Cannot delete nonexistent template: %s" % id)

	var dir := DirAccess.open(storage_dir)
	if dir == null:
		return Result.err("Failed to open templates directory: " + storage_dir)

	var error := dir.remove(id + ".json")
	if error != OK:
		return Result.err("Failed to delete template file: %s (error %d)" % [id, error])

	logger.info("Deleted template", {"id": id})
	return Result.ok(true)

## Checks if a template exists on disk
##
## Parameters:
##   id: Template ID to check
##
## Returns:
##   bool: True if template file exists
func template_exists(id: String) -> bool:
	return FileAccess.file_exists(_get_template_path(id))

## ============================================================================
## Private Helper Functions
## ============================================================================

## Gets the full file path for a template
func _get_template_path(id: String) -> String:
	return storage_dir + id + ".json"

## Ensures the storage directory exists, creates it if not
func _ensure_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(storage_dir):
		DirAccess.make_dir_recursive_absolute(storage_dir)
		logger.info("Created templates directory", {"path": storage_dir})
