## ExportManager
##
## Handles exporting generated images to the filesystem.
## Automatically handles filename conflicts and directory creation.
##
## Usage:
##   const ExportManager = preload("res://addons/ai_pixel_art_generator/storage/export_manager.gd")
##   var manager := ExportManager.new()
##   var result := manager.save_image(image, "my_pixel_art")

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

## Default export directory
const DEFAULT_EXPORT_DIR: String = "user://generated_assets/"

var export_dir: String
var logger: PluginLogger

## Constructor
##
## Parameters:
##   dir: Directory for exported images (default: user://generated_assets/)
func _init(dir: String = DEFAULT_EXPORT_DIR) -> void:
	export_dir = dir
	logger = PluginLogger.get_logger("ExportManager")

## Saves an image to the export directory
##
## Parameters:
##   image: Image to save
##   filename: Base filename (without path, .png extension optional)
##
## Returns:
##   Result<String>: Ok with full path to saved file, Err if failed
func save_image(image: Image, filename: String) -> Result:
	# Validate inputs
	if image == null:
		return Result.err("Cannot save null image")

	if filename.is_empty():
		return Result.err("Filename cannot be empty")

	# Ensure directory exists
	_ensure_directory_exists()

	# Ensure .png extension
	var final_filename := filename
	if not final_filename.ends_with(".png"):
		final_filename += ".png"

	# Handle filename conflicts
	var full_path := _get_unique_path(final_filename)

	# Save image
	var error := image.save_png(full_path)
	if error != OK:
		return Result.err("Failed to save image: %s (error %d)" % [full_path, error])

	logger.info("Exported image", {"path": full_path})
	return Result.ok(full_path)

## Saves an image with a timestamp in the filename
##
## Parameters:
##   image: Image to save
##   base_name: Base filename without extension
##
## Returns:
##   Result<String>: Ok with full path to saved file
func save_image_with_timestamp(image: Image, base_name: String) -> Result:
	var timestamp := Time.get_unix_time_from_system()
	var filename := "%s_%d.png" % [base_name, timestamp]
	return save_image(image, filename)

## Gets the configured export directory
##
## Returns:
##   String: Export directory path
func get_export_directory() -> String:
	return export_dir

## Lists all exported images in the directory
##
## Returns:
##   Result<Array>: Ok with array of filenames (not full paths)
func list_exported_images() -> Result:
	if not DirAccess.dir_exists_absolute(export_dir):
		return Result.ok([])  # No directory yet, return empty array

	var dir := DirAccess.open(export_dir)
	if dir == null:
		return Result.err("Failed to open export directory: " + export_dir)

	var images: Array = []

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			images.append(file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	return Result.ok(images)

## ============================================================================
## Private Helper Functions
## ============================================================================

func _ensure_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(export_dir):
		DirAccess.make_dir_recursive_absolute(export_dir)
		logger.info("Created export directory", {"path": export_dir})

func _get_unique_path(filename: String) -> String:
	var base_path := export_dir + filename

	# If file doesn't exist, use it as-is
	if not FileAccess.file_exists(base_path):
		return base_path

	# File exists, add number suffix
	var base_name := filename.get_basename()
	var extension := filename.get_extension()
	var counter := 1

	while true:
		var numbered_filename := "%s_%d.%s" % [base_name, counter, extension]
		var numbered_path := export_dir + numbered_filename

		if not FileAccess.file_exists(numbered_path):
			return numbered_path

		counter += 1

		# Safety limit to prevent infinite loop
		if counter > 9999:
			logger.warn("Hit safety limit for filename conflicts", {"base_name": base_name})
			return numbered_path

	# Unreachable, but satisfies static analysis
	return base_path
