## GenerationResult Model
##
## Stores the output of a complete generation pipeline execution.
## Contains all intermediate images at each stage of processing, plus any polish iterations.
##
## Usage:
##   const GenerationResult = preload("res://addons/ai_pixel_art_generator/models/generation_result.gd")
##   var result := GenerationResult.new(original, conformed, generated, pixelated, [], timestamp)
##   var final := result.get_final_image()

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

## Original reference image before processing
var original_image: Image = null

## Image after palette conformance
var palette_conformed_image: Image = null

## AI-generated image from Gemini
var generated_image: Image = null

## Final pixelated version
var pixelated_image: Image = null

## Array of polish iteration images
var polish_iterations: Array[Image] = []

## Unix timestamp when generation completed
var timestamp: int = 0

## Constructor
##
## Parameters:
##   p_original: Original reference image
##   p_palette_conformed: Image after palette conformance
##   p_generated: AI-generated image
##   p_pixelated: Final pixelated image
##   p_polish_iterations: Array of polish images
##   p_timestamp: Generation timestamp (0 = use current time)
func _init(
	p_original: Image = null,
	p_palette_conformed: Image = null,
	p_generated: Image = null,
	p_pixelated: Image = null,
	p_polish_iterations: Array[Image] = [],
	p_timestamp: int = 0
) -> void:
	original_image = p_original
	palette_conformed_image = p_palette_conformed
	generated_image = p_generated
	pixelated_image = p_pixelated
	polish_iterations = p_polish_iterations.duplicate()
	timestamp = p_timestamp if p_timestamp > 0 else Time.get_unix_time_from_system()

## Adds a polish iteration image to the result
##
## Parameters:
##   image: Polished image to add
func add_polish_iteration(image: Image) -> void:
	polish_iterations.append(image)

## Gets the latest polished image, or pixelated if no polish iterations exist
##
## Returns:
##   Result<Image>: Ok with image, or Err if no images available
func get_latest_polished() -> Result:
	if not polish_iterations.is_empty():
		return Result.ok(polish_iterations[polish_iterations.size() - 1])

	if pixelated_image != null:
		return Result.ok(pixelated_image)

	return Result.err("No images available in generation result")

## Gets the final image (latest polish or pixelated)
##
## This is an alias for get_latest_polished() for clarity.
##
## Returns:
##   Result<Image>: Ok with final image, or Err if no images available
func get_final_image() -> Result:
	return get_latest_polished()

## Validates that the generation result has at least a pixelated image
##
## Returns:
##   Result: Ok if valid, Err with error message if invalid
func validate() -> Result:
	if pixelated_image == null:
		return Result.err("GenerationResult must have at least a pixelated_image")

	return Result.ok(true)
