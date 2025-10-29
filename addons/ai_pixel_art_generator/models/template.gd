## Template Model
##
## Represents a reusable configuration for generating pixel art assets.
## Contains all necessary information for the generation pipeline including
## reference image, prompts, target resolution, and palette selection.
##
## Usage:
##   const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
##   var template := Template.new("id1", "NPC Template", "res://ref.png",
##                                "A pixel art character", Vector2i(32, 32), "db32")
##   var validation := template.validate()
##   if validation.is_ok():
##       var dict := template.to_dict()
##       # Save to storage...

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

## Unique identifier for the template
var id: String = ""

## Human-readable name for the template
var name: String = ""

## Path to the reference image used as visual guide
var reference_image_path: String = ""

## Base prompt describing what to generate
var base_prompt: String = ""

## Target resolution for the final pixelated output
var target_resolution: Vector2i = Vector2i(32, 32)

## Name of the color palette to use
var palette_name: String = ""

## Constructor with all properties
##
## Parameters:
##   p_id: Unique identifier
##   p_name: Display name
##   p_reference_image_path: Path to reference image
##   p_base_prompt: AI generation prompt
##   p_target_resolution: Final pixel art resolution
##   p_palette_name: Name of palette to use
func _init(
	p_id: String = "",
	p_name: String = "",
	p_reference_image_path: String = "",
	p_base_prompt: String = "",
	p_target_resolution: Vector2i = Vector2i(32, 32),
	p_palette_name: String = ""
) -> void:
	id = p_id
	name = p_name
	reference_image_path = p_reference_image_path
	base_prompt = p_base_prompt
	target_resolution = p_target_resolution
	palette_name = p_palette_name

## Validates that all required fields are present and valid
##
## Returns:
##   Result: Ok if valid, Err with error message if invalid
func validate() -> Result:
	if id.is_empty():
		return Result.err("Template ID cannot be empty")

	if name.is_empty():
		return Result.err("Template name cannot be empty")

	if reference_image_path.is_empty():
		return Result.err("Template reference_image_path cannot be empty")

	if base_prompt.is_empty():
		return Result.err("Template base_prompt cannot be empty")

	if target_resolution.x <= 0 or target_resolution.y <= 0:
		return Result.err("Template target_resolution must be positive (got %s)" % target_resolution)

	if palette_name.is_empty():
		return Result.err("Template palette_name cannot be empty")

	return Result.ok(true)

## Serializes the template to a dictionary
##
## Returns:
##   Dictionary: All template properties as dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"reference_image_path": reference_image_path,
		"base_prompt": base_prompt,
		"target_resolution": {
			"x": target_resolution.x,
			"y": target_resolution.y
		},
		"palette_name": palette_name
	}

## Creates a Template from a dictionary
##
## Parameters:
##   dict: Dictionary containing template properties
##
## Returns:
##   Result<Template>: Ok with Template if successful, Err with error message if invalid
static func from_dict(dict: Dictionary) -> Result:
	# Validate required keys
	if not dict.has("id"):
		return Result.err("Template dictionary missing required key 'id'")

	if not dict.has("name"):
		return Result.err("Template dictionary missing required key 'name'")

	if not dict.has("reference_image_path"):
		return Result.err("Template dictionary missing required key 'reference_image_path'")

	if not dict.has("base_prompt"):
		return Result.err("Template dictionary missing required key 'base_prompt'")

	if not dict.has("target_resolution"):
		return Result.err("Template dictionary missing required key 'target_resolution'")

	if not dict.has("palette_name"):
		return Result.err("Template dictionary missing required key 'palette_name'")

	# Parse target_resolution
	var resolution_data = dict["target_resolution"]
	var resolution: Vector2i

	if resolution_data is Dictionary:
		if not resolution_data.has("x") or not resolution_data.has("y"):
			return Result.err("Template target_resolution dictionary must have 'x' and 'y' keys")

		resolution = Vector2i(resolution_data["x"], resolution_data["y"])
	else:
		return Result.err("Template target_resolution must be a dictionary with 'x' and 'y' keys")

	# Create template (load current script to instantiate)
	var TemplateScript = load("res://addons/ai_pixel_art_generator/models/template.gd")
	var template = TemplateScript.new(
		dict["id"],
		dict["name"],
		dict["reference_image_path"],
		dict["base_prompt"],
		resolution,
		dict["palette_name"]
	)

	return Result.ok(template)
