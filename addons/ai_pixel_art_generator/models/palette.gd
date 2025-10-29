## Palette Model
##
## Represents a color palette used for pixel art generation.
## Contains a collection of colors and provides functionality to find
## the nearest color in the palette for a given input color.
##
## Usage:
##   const Palette = preload("res://addons/ai_pixel_art_generator/models/palette.gd")
##   var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
##   var palette := Palette.new("rgb", colors)
##   var nearest := palette.find_nearest_color(Color(0.9, 0.1, 0.1))

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

## Name of the palette
var name: String = ""

## Array of colors in the palette
var colors: Array[Color] = []

## Constructor
##
## Parameters:
##   p_name: Display name for the palette
##   p_colors: Array of Color objects in the palette
func _init(p_name: String = "", p_colors: Array[Color] = []) -> void:
	name = p_name
	colors = p_colors.duplicate()  # Create a copy to avoid external mutation

## Finds the nearest color in the palette to the given input color
##
## Uses Euclidean distance in RGB space to find the closest match.
##
## Parameters:
##   color: The input color to match
##
## Returns:
##   Result<Color>: Ok with the nearest color, or Err if palette is empty
func find_nearest_color(color: Color) -> Result:
	if colors.is_empty():
		return Result.err("Cannot find nearest color in empty palette")

	var nearest_color: Color = colors[0]
	var min_distance: float = _color_distance(color, nearest_color)

	for i in range(1, colors.size()):
		var distance := _color_distance(color, colors[i])
		if distance < min_distance:
			min_distance = distance
			nearest_color = colors[i]

	return Result.ok(nearest_color)

## Calculates the Euclidean distance between two colors in RGB space
##
## Parameters:
##   c1: First color
##   c2: Second color
##
## Returns:
##   float: Distance between the colors
func _color_distance(c1: Color, c2: Color) -> float:
	var dr := c1.r - c2.r
	var dg := c1.g - c2.g
	var db := c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db)

## Validates that a string is a valid hexadecimal color
##
## Parameters:
##   hex_str: Hex string without # prefix (e.g. "ff0000" or "ff0000ff")
##
## Returns:
##   bool: True if valid hex color format
static func _is_valid_hex_color(hex_str: String) -> bool:
	# Must be 6 (RGB) or 8 (RGBA) characters
	if hex_str.length() != 6 and hex_str.length() != 8:
		return false

	# All characters must be hex digits
	var hex_chars := "0123456789abcdefABCDEF"
	for i in range(hex_str.length()):
		if not hex_chars.contains(hex_str[i]):
			return false

	return true

## Validates that the palette has a name and at least one color
##
## Returns:
##   Result: Ok if valid, Err with error message if invalid
func validate() -> Result:
	if name.is_empty():
		return Result.err("Palette name cannot be empty")

	if colors.is_empty():
		return Result.err("Palette must have at least one color")

	return Result.ok(true)

## Serializes the palette to a dictionary
##
## Returns:
##   Dictionary: Palette data with name and colors as hex strings
func to_dict() -> Dictionary:
	var color_strings: Array = []
	for color in colors:
		# Convert to hex string (without #)
		color_strings.append(color.to_html(false))

	return {
		"name": name,
		"colors": color_strings
	}

## Creates a Palette from a dictionary
##
## Parameters:
##   dict: Dictionary containing palette data
##
## Returns:
##   Result<Palette>: Ok with Palette if successful, Err with error message if invalid
static func from_dict(dict: Dictionary) -> Result:
	# Validate required keys
	if not dict.has("name"):
		return Result.err("Palette dictionary missing required key 'name'")

	if not dict.has("colors"):
		return Result.err("Palette dictionary missing required key 'colors'")

	# Parse colors
	var colors_data = dict["colors"]
	if not colors_data is Array:
		return Result.err("Palette 'colors' must be an array")

	var parsed_colors: Array[Color] = []
	for i in range(colors_data.size()):
		var color_str = colors_data[i]
		if not color_str is String:
			return Result.err("Palette color at index %d is not a string" % i)

		# Validate color string format (basic check for hex colors)
		var hex_str: String = color_str.strip_edges()
		if hex_str.begins_with("#"):
			hex_str = hex_str.substr(1)

		# Check if it's a valid hex string (6 or 8 characters, all hex digits)
		if not _is_valid_hex_color(hex_str):
			return Result.err("Palette color at index %d has invalid format: '%s'" % [i, color_str])

		# Parse color from string (handles both #ff0000 and ff0000 formats)
		var color := Color(color_str)
		parsed_colors.append(color)

	# Create palette (load current script to instantiate)
	var PaletteScript = load("res://addons/ai_pixel_art_generator/models/palette.gd")
	var palette = PaletteScript.new(dict["name"], parsed_colors)

	return Result.ok(palette)
