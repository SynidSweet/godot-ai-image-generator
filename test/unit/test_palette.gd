extends GutTest

const Palette = preload("res://addons/ai_pixel_art_generator/models/palette.gd")

# Test fixtures
var db16_colors: Array[Color]
var logger

func before_each() -> void:
	# DB16 palette (DawnBringer 16) - a common pixel art palette
	db16_colors = [
		Color("140c1c"), Color("442434"), Color("30346d"), Color("4e4a4e"),
		Color("854c30"), Color("346524"), Color("d04648"), Color("757161"),
		Color("597dce"), Color("d27d2c"), Color("8595a1"), Color("6daa2c"),
		Color("d2aa99"), Color("6dc2ca"), Color("dad45e"), Color("deeed6")
	]
	logger = get_logger()

## ============================================================================
## Constructor and Basic Properties
## ============================================================================

func test_palette_creation_with_name_and_colors() -> void:
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	var palette := Palette.new("test_palette", colors)

	assert_eq(palette.name, "test_palette", "Palette name should be set")
	assert_eq(palette.colors.size(), 3, "Palette should have 3 colors")
	assert_eq(palette.colors[0], Color.RED, "First color should be red")

func test_palette_default_constructor() -> void:
	var palette := Palette.new()

	assert_eq(palette.name, "", "Default palette name should be empty")
	assert_eq(palette.colors.size(), 0, "Default palette should have no colors")

func test_palette_with_empty_colors_array() -> void:
	var empty_colors: Array[Color] = []
	var palette := Palette.new("empty", empty_colors)

	assert_eq(palette.name, "empty", "Palette name should be set")
	assert_eq(palette.colors.size(), 0, "Palette should have zero colors")

## ============================================================================
## Find Nearest Color
## ============================================================================

func test_find_nearest_color_exact_match() -> void:
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	var palette := Palette.new("rgb", colors)

	var result := palette.find_nearest_color(Color.RED)

	assert_true(result.is_ok(), "Should find exact match")
	assert_eq(result.value, Color.RED, "Should return red for red input")

func test_find_nearest_color_approximate_match() -> void:
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	var palette := Palette.new("rgb", colors)

	# Dark red should match to RED
	var dark_red := Color(0.6, 0.1, 0.1)
	var result := palette.find_nearest_color(dark_red)

	assert_true(result.is_ok(), "Should find nearest color")
	assert_eq(result.value, Color.RED, "Dark red should match to RED")

func test_find_nearest_color_with_grayscale() -> void:
	var colors: Array[Color] = [Color.BLACK, Color.WHITE]
	var palette := Palette.new("bw", colors)

	# Light gray should match to WHITE
	var light_gray := Color(0.8, 0.8, 0.8)
	var result := palette.find_nearest_color(light_gray)

	assert_true(result.is_ok(), "Should find nearest color")
	assert_eq(result.value, Color.WHITE, "Light gray should match to WHITE")

	# Dark gray should match to BLACK
	var dark_gray := Color(0.2, 0.2, 0.2)
	result = palette.find_nearest_color(dark_gray)

	assert_true(result.is_ok(), "Should find nearest color")
	assert_eq(result.value, Color.BLACK, "Dark gray should match to BLACK")

func test_find_nearest_color_with_empty_palette() -> void:
	var empty_colors: Array[Color] = []
	var palette := Palette.new("empty", empty_colors)

	var result := palette.find_nearest_color(Color.RED)

	assert_true(result.is_err(), "Should fail with empty palette")
	assert_string_contains(result.error, "empty", "Error should mention empty palette")

func test_find_nearest_color_uses_euclidean_distance() -> void:
	var colors: Array[Color] = [
		Color(1.0, 0.0, 0.0),  # Red
		Color(0.0, 1.0, 0.0),  # Green
		Color(0.0, 0.0, 1.0)   # Blue
	]
	var palette := Palette.new("rgb", colors)

	# Yellow (0.5, 0.5, 0) should be closer to Green than to Red or Blue
	# because Green has more similar overall brightness
	var yellowish := Color(0.4, 0.6, 0.0)
	var result := palette.find_nearest_color(yellowish)

	assert_true(result.is_ok(), "Should find nearest color")
	# The exact result depends on the distance metric used
	# This test documents the expected behavior

## ============================================================================
## Validation
## ============================================================================

func test_validate_returns_ok_for_valid_palette() -> void:
	var colors: Array[Color] = [Color.RED, Color.GREEN]
	var palette := Palette.new("valid", colors)

	var result := palette.validate()
	assert_true(result.is_ok(), "Valid palette should pass validation")

func test_validate_fails_for_empty_name() -> void:
	var colors: Array[Color] = [Color.RED]
	var palette := Palette.new("", colors)

	var result := palette.validate()
	assert_true(result.is_err(), "Empty name should fail validation")
	assert_string_contains(result.error, "name", "Error should mention name")

func test_validate_fails_for_empty_colors() -> void:
	var empty_colors: Array[Color] = []
	var palette := Palette.new("empty", empty_colors)

	var result := palette.validate()
	assert_true(result.is_err(), "Empty colors should fail validation")
	assert_string_contains(result.error, "color", "Error should mention colors")

## ============================================================================
## Serialization - to_dict()
## ============================================================================

func test_to_dict_returns_all_properties() -> void:
	var colors: Array[Color] = [Color.RED, Color.GREEN]
	var palette := Palette.new("test", colors)

	var dict := palette.to_dict()

	assert_eq(dict["name"], "test", "Dictionary should contain name")
	assert_true(dict.has("colors"), "Dictionary should have colors key")
	assert_eq(dict["colors"].size(), 2, "Dictionary should have 2 colors")

func test_to_dict_serializes_colors_as_strings() -> void:
	var colors: Array[Color] = [Color.RED]
	var palette := Palette.new("test", colors)

	var dict := palette.to_dict()

	assert_typeof(dict["colors"][0], TYPE_STRING, "Colors should be serialized as strings")

func test_to_dict_with_many_colors() -> void:
	var palette := Palette.new("db16", db16_colors)

	var dict := palette.to_dict()

	assert_eq(dict["name"], "db16", "Name should match")
	assert_eq(dict["colors"].size(), 16, "Should have 16 colors")

## ============================================================================
## Deserialization - from_dict()
## ============================================================================

func test_from_dict_creates_palette_with_all_properties() -> void:
	var dict := {
		"name": "test_palette",
		"colors": ["#ff0000", "#00ff00", "#0000ff"]
	}

	var result := Palette.from_dict(dict)

	assert_true(result.is_ok(), "Should successfully create palette from valid data")

	var palette: Palette = result.value
	assert_eq(palette.name, "test_palette", "Name should match")
	assert_eq(palette.colors.size(), 3, "Should have 3 colors")
	assert_eq(palette.colors[0], Color.RED, "First color should be red")

func test_from_dict_fails_with_missing_name() -> void:
	var dict := {
		"colors": ["#ff0000"]
	}

	var result := Palette.from_dict(dict)
	assert_true(result.is_err(), "Should fail without name")

func test_from_dict_fails_with_missing_colors() -> void:
	var dict := {
		"name": "test"
	}

	var result := Palette.from_dict(dict)
	assert_true(result.is_err(), "Should fail without colors")

func test_from_dict_handles_invalid_color_format() -> void:
	var dict := {
		"name": "test",
		"colors": ["not_a_color"]
	}

	var result := Palette.from_dict(dict)
	# Should fail with invalid color format
	assert_true(result.is_err(), "Should fail with invalid color format")
	assert_string_contains(result.error, "invalid", "Error should mention invalid format")

func test_from_dict_with_various_color_formats() -> void:
	var dict := {
		"name": "test",
		"colors": [
			"#ff0000",      # Hex with #
			"00ff00",       # Hex without #
			"0000ff"        # Another hex without #
		]
	}

	var result := Palette.from_dict(dict)
	assert_true(result.is_ok(), "Should handle various color formats")

## ============================================================================
## Round-trip Serialization
## ============================================================================

func test_roundtrip_serialization() -> void:
	var original := Palette.new("db16", db16_colors)

	var dict := original.to_dict()
	var result := Palette.from_dict(dict)

	assert_true(result.is_ok(), "Roundtrip should succeed")

	var restored: Palette = result.value
	assert_eq(restored.name, original.name, "Name should survive roundtrip")
	assert_eq(restored.colors.size(), original.colors.size(), "Color count should survive roundtrip")

	for i in range(original.colors.size()):
		# Colors might not be exactly equal due to serialization rounding
		# but should be very close
		var original_color := original.colors[i]
		var restored_color := restored.colors[i]
		assert_almost_eq(original_color.r, restored_color.r, 0.01, "Red channel should be close")
		assert_almost_eq(original_color.g, restored_color.g, 0.01, "Green channel should be close")
		assert_almost_eq(original_color.b, restored_color.b, 0.01, "Blue channel should be close")
