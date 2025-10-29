extends Node

## Generation Pipeline Orchestrator
##
## Coordinates the multi-step process of generating pixel art images:
## 1. Load reference image and palette
## 2. Conform image to palette colors
## 3. Generate via Gemini API
## 4. Pixelate to target resolution
## 5. Optional polish iterations
##
## Usage:
##   var pipeline := GenerationPipeline.new()
##   add_child(pipeline)
##   pipeline.generation_complete.connect(_on_complete)
##   pipeline.progress_updated.connect(_on_progress)
##   pipeline.generate(template, settings)

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")
const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
const GenerationSettings = preload("res://addons/ai_pixel_art_generator/models/generation_settings.gd")
const GenerationResult = preload("res://addons/ai_pixel_art_generator/models/generation_result.gd")

## Pipeline states
enum State {
	IDLE,        ## Not currently processing
	PROCESSING,  ## Generation in progress
	COMPLETED,   ## Generation finished successfully
	ERROR        ## Generation failed
}

## Signal emitted when generation completes (success or failure)
## Emits a Result<GenerationResult>
signal generation_complete(result)

## Signal emitted when progress updates
## Emits (current_step: int, total_steps: int, message: String)
signal progress_updated(current_step, total_steps, message)

var _state: State = State.IDLE
var _current_step: int = 0
var _total_steps: int = 0
var _progress_message: String = ""
var _logger: PluginLogger

# Dependencies (injected)
var _image_processor: Variant = null
var _gemini_client: Variant = null
var _palette_repository: Variant = null
var _settings_repository: Variant = null

# Generation context (for async callback)
var _current_generation_context: Dictionary = {}


func _init() -> void:
	_logger = PluginLogger.get_logger("GenerationPipeline")


## Initializes the pipeline with dependencies
func initialize(image_processor: Variant, gemini_client: Variant,
				palette_repository: Variant, settings_repository: Variant) -> void:
	_image_processor = image_processor
	_gemini_client = gemini_client
	_palette_repository = palette_repository
	_settings_repository = settings_repository

	_logger.info("Pipeline initialized with dependencies")


## Generates a pixel art image using the template and settings
##
## This is the main entry point for the pipeline.
## The process is async - connect to generation_complete signal for result.
func generate(template: Template, settings: GenerationSettings) -> void:
	# Validate inputs
	var template_validation := validate_template(template)
	if template_validation.is_err():
		_emit_error(template_validation.error)
		return

	var settings_validation := validate_settings(settings)
	if settings_validation.is_err():
		_emit_error(settings_validation.error)
		return

	_logger.info("Starting generation", {
		"template": template.name,
		"resolution": "%dx%d" % [template.target_resolution.x, template.target_resolution.y]
	})

	set_pipeline_state(State.PROCESSING)
	set_pipeline_progress(0, 5, "Initializing")

	# Start async generation process
	_run_generation_async(template, settings)


## Validates a template
func validate_template(template: Template) -> Result:
	if template == null:
		return Result.err("Template cannot be null")

	var validation := template.validate()
	if validation.is_err():
		return Result.err("Template validation failed: %s" % validation.error)

	return Result.ok(true)


## Validates generation settings
func validate_settings(settings: GenerationSettings) -> Result:
	if settings == null:
		return Result.err("Settings cannot be null")

	var validation := settings.validate()
	if validation.is_err():
		return Result.err("Settings validation failed: %s" % validation.error)

	return Result.ok(true)


## Builds the full prompt by combining base and detail prompts
func build_full_prompt(template: Template, settings: GenerationSettings) -> Result:
	var base := template.base_prompt.strip_edges()
	var detail := settings.detail_prompt.strip_edges()

	if base.is_empty() and detail.is_empty():
		return Result.err("Cannot build prompt: both base and detail prompts are empty")

	if detail.is_empty():
		return Result.ok(base)

	if base.is_empty():
		return Result.ok(detail)

	return Result.ok("%s. %s" % [base, detail])


## Loads a reference image from a file path
func load_reference_image(path: String) -> Result:
	if path.is_empty():
		return Result.err("Image path cannot be empty")

	var image := Image.new()
	var error := image.load(path)

	if error != OK:
		return Result.err("Failed to load image from %s (error code: %d)" % [path, error])

	if image.is_empty():
		return Result.err("Loaded image is empty: %s" % path)

	return Result.ok(image)


## Cancels the current generation
func cancel() -> Result:
	if _state != State.PROCESSING:
		return Result.err("Cannot cancel: not currently processing")

	_logger.info("Generation cancelled by user")
	set_pipeline_state(State.IDLE)
	set_pipeline_progress(0, 0, "Cancelled")

	return Result.ok(true)


## Gets the current pipeline state
func get_state() -> State:
	return _state


## Checks if pipeline is idle
func is_idle() -> bool:
	return _state == State.IDLE


## Checks if pipeline is processing
func is_processing() -> bool:
	return _state == State.PROCESSING


## Checks if pipeline has completed
func is_completed() -> bool:
	return _state == State.COMPLETED


## Checks if pipeline is in error state
func is_error() -> bool:
	return _state == State.ERROR


## Gets current progress as percentage (0.0 to 100.0)
func get_progress_percentage() -> float:
	if _total_steps == 0:
		return 0.0
	return (_current_step / float(_total_steps)) * 100.0


## Gets the current progress message
func get_progress_message() -> String:
	return _progress_message


## Sets the pipeline state (public for testing)
func set_pipeline_state(new_state: State) -> void:
	_state = new_state
	_logger.debug("State changed", {"state": _state_to_string(new_state)})


## Updates progress (public for testing)
func set_pipeline_progress(current: int, total: int, message: String) -> void:
	_current_step = current
	_total_steps = total
	_progress_message = message

	progress_updated.emit(current, total, message)

	_logger.debug("Progress updated", {
		"step": "%d/%d" % [current, total],
		"message": message
	})


## Internal: Emits an error result
func _emit_error(error_message: String) -> void:
	set_pipeline_state(State.ERROR)
	_logger.error("Generation failed", {"error": error_message})
	generation_complete.emit(Result.err(error_message))


## Internal: Converts state enum to string
func _state_to_string(state: State) -> String:
	match state:
		State.IDLE: return "IDLE"
		State.PROCESSING: return "PROCESSING"
		State.COMPLETED: return "COMPLETED"
		State.ERROR: return "ERROR"
		_: return "UNKNOWN"


## Internal: Runs the async generation process
func _run_generation_async(template: Template, settings: GenerationSettings) -> void:
	# Check dependencies
	if _image_processor == null:
		_emit_error("ImageProcessor not initialized")
		return
	if _gemini_client == null:
		_emit_error("GeminiClient not initialized")
		return
	if _palette_repository == null:
		_emit_error("PaletteRepository not initialized")
		return
	if _settings_repository == null:
		_emit_error("SettingsRepository not initialized")
		return

	# Step 1: Load and conform reference image to palette
	set_pipeline_progress(1, 5, "Loading reference image")

	var ref_image_result := load_reference_image(template.reference_image_path)
	if ref_image_result.is_err():
		_emit_error("Failed to load reference image: %s" % ref_image_result.error)
		return

	var reference_image: Image = ref_image_result.value

	# Load palette
	var palette_result: Variant = _palette_repository.load_palette(template.palette_name)
	if palette_result.is_err():
		_emit_error("Failed to load palette: %s" % palette_result.error)
		return

	var palette = palette_result.value

	# Conform reference image to palette
	set_pipeline_progress(2, 5, "Conforming to palette")

	var conform_result: Variant = _image_processor.conform_to_palette(reference_image, palette, true)
	if conform_result.is_err():
		_emit_error("Failed to conform image to palette: %s" % conform_result.error)
		return

	var conformed_image: Image = conform_result.value

	# Step 2: Generate via Gemini API (async)
	set_pipeline_progress(3, 5, "Generating via AI")

	# Build full prompt
	var prompt_result := build_full_prompt(template, settings)
	if prompt_result.is_err():
		_emit_error("Failed to build prompt: %s" % prompt_result.error)
		return

	var full_prompt: String = prompt_result.value

	# Get API key
	var api_key_result: Variant = _settings_repository.load_api_key()
	if api_key_result.is_err():
		_emit_error("No API key configured. Please add your Gemini API key in Settings.")
		return

	# Configure Gemini client
	_gemini_client.api_key = api_key_result.value
	_gemini_client.temperature = settings.temperature

	# Connect to API response (one-time connection)
	if not _gemini_client.generation_complete.is_connected(_on_api_generation_complete):
		_gemini_client.generation_complete.connect(_on_api_generation_complete)

	# Store context for async callback
	_current_generation_context = {
		"template": template,
		"conformed_image": conformed_image
	}

	# Start async API call
	_gemini_client.generate_image(full_prompt, conformed_image)


## Internal: Handles Gemini API response
func _on_api_generation_complete(result: Variant) -> void:
	# Check if we have context
	if _current_generation_context.is_empty():
		_emit_error("API response received but no generation context found")
		return

	var template: Template = _current_generation_context.get("template")
	var conformed_image: Image = _current_generation_context.get("conformed_image")

	# Clear context
	_current_generation_context.clear()

	# Check API result
	if result.is_err():
		_emit_error("AI generation failed: %s" % result.error)
		return

	var generated_image: Image = result.value

	# Step 3: Pixelate the generated image
	set_pipeline_progress(4, 5, "Pixelating to target resolution")

	var pixelate_result: Variant = _image_processor.pixelate(
		generated_image,
		template.target_resolution
	)

	if pixelate_result.is_err():
		_emit_error("Failed to pixelate image: %s" % pixelate_result.error)
		return

	var pixelated_image: Image = pixelate_result.value

	# Step 4: Upscale the pixelated image
	set_pipeline_progress(5, 5, "Upscaling final image")

	var upscale_result: Variant = _image_processor.upscale_pixelated(pixelated_image, 4)

	if upscale_result.is_err():
		_emit_error("Failed to upscale image: %s" % upscale_result.error)
		return

	var upscaled_image: Image = upscale_result.value

	# Create result object
	var gen_result := GenerationResult.new()
	gen_result.original_image = reference_image
	gen_result.palette_conformed_image = conformed_image
	gen_result.generated_image = generated_image
	gen_result.pixelated_image = pixelated_image  # Store the small pixelated version

	# Store upscaled as a polish iteration for now (hacky but works with current model)
	gen_result.add_polish_iteration(upscaled_image)

	# Emit success
	set_pipeline_state(State.COMPLETED)
	_logger.info("Generation completed successfully")
	generation_complete.emit(Result.ok(gen_result))
