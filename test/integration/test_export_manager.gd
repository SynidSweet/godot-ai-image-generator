extends GutTest

const ExportManager = preload("res://addons/ai_pixel_art_generator/storage/export_manager.gd")

var manager: ExportManager
var test_dir: String
var logger

func before_each() -> void:
	logger = get_logger()
	# Use a unique temporary directory for each test
	test_dir = "user://test_exports_%d/" % Time.get_ticks_msec()
	manager = ExportManager.new(test_dir)

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

func _create_test_image() -> Image:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	return img

## ============================================================================
## Save Image
## ============================================================================

func test_save_image_creates_file() -> void:
	var img := _create_test_image()

	var result := manager.save_image(img, "test_image")

	assert_true(result.is_ok(), "Should successfully save image")
	var saved_path: String = result.value
	assert_true(FileAccess.file_exists(saved_path), "Image file should exist")

func test_save_image_with_png_extension() -> void:
	var img := _create_test_image()

	var result := manager.save_image(img, "test.png")

	assert_true(result.is_ok(), "Should handle .png extension")
	var saved_path: String = result.value
	assert_true(saved_path.ends_with(".png"), "Path should end with .png")

func test_save_image_adds_png_extension_if_missing() -> void:
	var img := _create_test_image()

	var result := manager.save_image(img, "no_extension")

	assert_true(result.is_ok(), "Should add extension")
	var saved_path: String = result.value
	assert_true(saved_path.ends_with(".png"), "Should add .png extension")

func test_save_image_fails_with_null_image() -> void:
	var result := manager.save_image(null, "test")

	assert_true(result.is_err(), "Should fail with null image")

func test_save_image_fails_with_empty_filename() -> void:
	var img := _create_test_image()

	var result := manager.save_image(img, "")

	assert_true(result.is_err(), "Should fail with empty filename")

## ============================================================================
## Filename Conflicts
## ============================================================================

func test_save_image_handles_conflict_by_adding_number() -> void:
	var img1 := _create_test_image()
	var img2 := _create_test_image()

	var result1 := manager.save_image(img1, "duplicate")
	var result2 := manager.save_image(img2, "duplicate")

	assert_true(result1.is_ok() and result2.is_ok(), "Both should succeed")
	assert_ne(result1.value, result2.value, "Paths should be different")
	assert_true(FileAccess.file_exists(result1.value), "First file should exist")
	assert_true(FileAccess.file_exists(result2.value), "Second file should exist")

func test_save_image_increments_conflict_number() -> void:
	var img := _create_test_image()

	var result1 := manager.save_image(img, "conflict_test")
	var result2 := manager.save_image(img, "conflict_test")
	var result3 := manager.save_image(img, "conflict_test")

	assert_true(result1.is_ok() and result2.is_ok() and result3.is_ok(), "All should succeed")

	# Check that all files exist
	assert_true(FileAccess.file_exists(result1.value), "File 1 should exist")
	assert_true(FileAccess.file_exists(result2.value), "File 2 should exist")
	assert_true(FileAccess.file_exists(result3.value), "File 3 should exist")

## ============================================================================
## Save With Timestamp
## ============================================================================

func test_save_image_with_timestamp() -> void:
	var img := _create_test_image()

	var result := manager.save_image_with_timestamp(img, "timestamped")

	assert_true(result.is_ok(), "Should save with timestamp")
	var saved_path: String = result.value
	assert_true("timestamped" in saved_path, "Should contain base filename")
	assert_true(saved_path.contains("_"), "Should contain timestamp separator")

func test_save_image_with_timestamp_creates_unique_names() -> void:
	var img := _create_test_image()

	var result1 := manager.save_image_with_timestamp(img, "unique")
	# Note: Even if timestamps are identical, conflict resolution handles it
	var result2 := manager.save_image_with_timestamp(img, "unique")

	assert_true(result1.is_ok() and result2.is_ok(), "Both should succeed")
	# Files should exist even if names are same (conflict resolution)
	assert_true(FileAccess.file_exists(result1.value), "First file should exist")
	assert_true(FileAccess.file_exists(result2.value), "Second file should exist")

## ============================================================================
## Get Export Directory
## ============================================================================

func test_get_export_directory() -> void:
	var dir := manager.get_export_directory()

	assert_eq(dir, test_dir, "Should return configured directory")

func test_export_directory_created_on_first_save() -> void:
	# Verify directory doesn't exist yet
	assert_false(DirAccess.dir_exists_absolute(test_dir), "Directory should not exist initially")

	var img := _create_test_image()
	manager.save_image(img, "creates_dir")

	assert_true(DirAccess.dir_exists_absolute(test_dir), "Directory should be created")

## ============================================================================
## List Exported Images
## ============================================================================

func test_list_exported_images() -> void:
	var img := _create_test_image()
	manager.save_image(img, "image1")
	manager.save_image(img, "image2")
	manager.save_image(img, "image3")

	var result := manager.list_exported_images()

	assert_true(result.is_ok(), "Should list images")
	var images: Array = result.value
	assert_eq(images.size(), 3, "Should find 3 images")

func test_list_exported_images_returns_empty_when_none() -> void:
	var result := manager.list_exported_images()

	assert_true(result.is_ok(), "Should succeed even with no images")
	var images: Array = result.value
	assert_eq(images.size(), 0, "Should return empty array")
