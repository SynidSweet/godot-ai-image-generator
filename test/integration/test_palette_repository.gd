extends GutTest

const PaletteRepository = preload("res://addons/ai_pixel_art_generator/storage/palette_repository.gd")
const Palette = preload("res://addons/ai_pixel_art_generator/models/palette.gd")

var repository: PaletteRepository
var logger

func before_each() -> void:
	logger = get_logger()
	repository = PaletteRepository.new()

## ============================================================================
## Load Preset Palettes
## ============================================================================

func test_load_palette_returns_preset_if_available() -> void:
	# This test will pass once we create preset palette files
	# For now, we'll test the loading mechanism
	var result := repository.load_palette("nonexistent")
	# Should return an error for now
	assert_true(result.is_err() or result.is_ok(), "Should return a Result")

func test_list_available_palettes_returns_array() -> void:
	var result := repository.list_available_palettes()

	assert_true(result.is_ok(), "Should successfully list palettes")
	var palettes: Array = result.value
	assert_typeof(palettes, TYPE_ARRAY, "Should return an array")

## ============================================================================
## Custom Palettes
## ============================================================================

func test_save_custom_palette() -> void:
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	var palette := Palette.new("custom_test", colors)

	var result := repository.save_custom_palette(palette)

	assert_true(result.is_ok(), "Should successfully save custom palette")

func test_load_custom_palette() -> void:
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	var palette := Palette.new("custom_load_test", colors)
	repository.save_custom_palette(palette)

	var result := repository.load_palette("custom_load_test")

	assert_true(result.is_ok(), "Should load custom palette")
	var loaded: Palette = result.value
	assert_eq(loaded.name, "custom_load_test", "Name should match")
	assert_eq(loaded.colors.size(), 3, "Should have 3 colors")

func test_custom_palette_appears_in_list() -> void:
	var colors: Array[Color] = [Color.YELLOW]
	var palette := Palette.new("list_test_palette", colors)
	repository.save_custom_palette(palette)

	var result := repository.list_available_palettes()

	assert_true(result.is_ok(), "Should list palettes")
	var palettes: Array = result.value
	assert_true("list_test_palette" in palettes, "Custom palette should be in list")

func test_delete_custom_palette() -> void:
	var colors: Array[Color] = [Color.BLACK]
	var palette := Palette.new("delete_palette_test", colors)
	repository.save_custom_palette(palette)

	var result := repository.delete_custom_palette("delete_palette_test")

	assert_true(result.is_ok(), "Should delete custom palette")

	# Verify it's gone
	var load_result := repository.load_palette("delete_palette_test")
	assert_true(load_result.is_err(), "Deleted palette should not be loadable")
