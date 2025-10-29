## PaletteRepository
##
## Handles loading preset palettes and managing custom user palettes.
## Preset palettes are stored in res://addons/.../data/palettes/
## Custom palettes are stored in user://palettes/
##
## Usage:
##   const PaletteRepository = preload("res://addons/ai_pixel_art_generator/storage/palette_repository.gd")
##   var repo := PaletteRepository.new()
##   var result := repo.load_palette("db32")

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const Palette = preload("res://addons/ai_pixel_art_generator/models/palette.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

## Directory for preset palettes (bundled with plugin)
const PRESET_DIR: String = "res://addons/ai_pixel_art_generator/data/palettes/"

## Directory for custom user palettes
const CUSTOM_DIR: String = "user://palettes/"

var logger: PluginLogger

func _init() -> void:
	logger = PluginLogger.get_logger("PaletteRepository")
	_ensure_custom_directory_exists()

## Loads a palette by name (checks custom first, then presets)
##
## Parameters:
##   name: Palette name to load
##
## Returns:
##   Result<Palette>: Ok with palette if found, Err if not found
func load_palette(name: String) -> Result:
	# Try custom palettes first
	var custom_path := CUSTOM_DIR + name + ".json"
	if FileAccess.file_exists(custom_path):
		return _load_palette_from_file(custom_path, name)

	# Try preset palettes
	var preset_path := PRESET_DIR + name + ".json"
	if FileAccess.file_exists(preset_path):
		return _load_palette_from_file(preset_path, name)

	return Result.err("Palette not found: %s" % name)

## Lists all available palette names (presets + custom)
##
## Returns:
##   Result<Array>: Ok with array of palette names
func list_available_palettes() -> Result:
	var palette_names: Array = []

	# List preset palettes
	var preset_dir := DirAccess.open(PRESET_DIR)
	if preset_dir:
		preset_dir.list_dir_begin()
		var file_name := preset_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				palette_names.append(file_name.get_basename())
			file_name = preset_dir.get_next()
		preset_dir.list_dir_end()

	# List custom palettes
	_ensure_custom_directory_exists()
	var custom_dir := DirAccess.open(CUSTOM_DIR)
	if custom_dir:
		custom_dir.list_dir_begin()
		var file_name := custom_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var name := file_name.get_basename()
				if name not in palette_names:  # Avoid duplicates
					palette_names.append(name)
			file_name = custom_dir.get_next()
		custom_dir.list_dir_end()

	logger.info("Listed palettes", {"count": palette_names.size()})
	return Result.ok(palette_names)

## Saves a custom palette
##
## Parameters:
##   palette: Palette to save
##
## Returns:
##   Result: Ok if saved successfully
func save_custom_palette(palette: Palette) -> Result:
	var validation := palette.validate()
	if validation.is_err():
		return Result.err("Cannot save invalid palette: " + validation.error)

	_ensure_custom_directory_exists()

	var palette_dict := palette.to_dict()
	var json_string := JSON.stringify(palette_dict, "\t")

	var file_path := CUSTOM_DIR + palette.name + ".json"
	var file := FileAccess.open(file_path, FileAccess.WRITE)

	if file == null:
		var error := FileAccess.get_open_error()
		return Result.err("Failed to save custom palette: %s (error %d)" % [palette.name, error])

	file.store_string(json_string)
	file.close()

	logger.info("Saved custom palette", {"name": palette.name})
	return Result.ok(true)

## Deletes a custom palette
##
## Parameters:
##   name: Name of palette to delete
##
## Returns:
##   Result: Ok if deleted successfully
func delete_custom_palette(name: String) -> Result:
	var file_path := CUSTOM_DIR + name + ".json"

	if not FileAccess.file_exists(file_path):
		return Result.err("Custom palette not found: %s" % name)

	var dir := DirAccess.open(CUSTOM_DIR)
	if dir == null:
		return Result.err("Failed to open custom palettes directory")

	var error := dir.remove(name + ".json")
	if error != OK:
		return Result.err("Failed to delete custom palette: %s (error %d)" % [name, error])

	logger.info("Deleted custom palette", {"name": name})
	return Result.ok(true)

## ============================================================================
## Private Helper Functions
## ============================================================================

func _load_palette_from_file(file_path: String, name: String) -> Result:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return Result.err("Failed to open palette file: %s" % file_path)

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(json_string)

	if parse_error != OK:
		return Result.err("Failed to parse palette JSON: %s" % name)

	var data = json.get_data()
	if not data is Dictionary:
		return Result.err("Palette JSON is not a dictionary: %s" % name)

	var palette_result := Palette.from_dict(data)
	if palette_result.is_err():
		return palette_result

	logger.info("Loaded palette", {"name": name})
	return palette_result

func _ensure_custom_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(CUSTOM_DIR):
		DirAccess.make_dir_recursive_absolute(CUSTOM_DIR)
