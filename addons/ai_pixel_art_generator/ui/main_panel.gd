@tool
extends VBoxContainer

## Main Panel UI Controller
##
## Main UI panel for the AI Pixel Art Generator plugin.
## Manages template selection, generation workflow, and output display.

const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")
const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
const GenerationSettings = preload("res://addons/ai_pixel_art_generator/models/generation_settings.gd")
const TemplateEditorDialog = preload("res://addons/ai_pixel_art_generator/ui/dialogs/template_editor_dialog.tscn")

var _logger: PluginLogger
var _template_manager: Variant = null
var _generation_pipeline: Variant = null
var _export_manager: Variant = null
var _selected_template: Template = null
var _template_editor: ConfirmationDialog = null
var _generated_result: Variant = null  # Stores GenerationResult

# UI node references - Template selector
@onready var _template_dropdown: OptionButton = $TemplateSelector/TemplateDropdown
@onready var _new_button: Button = $TemplateSelector/NewButton
@onready var _edit_button: Button = $TemplateSelector/EditButton
@onready var _delete_button: Button = $TemplateSelector/DeleteButton

# UI node references - Input section
@onready var _ref_image_preview: TextureRect = $InputSection/ReferenceImagePanel/ImagePreview
@onready var _select_image_button: Button = $InputSection/ReferenceImagePanel/SelectImageButton
@onready var _base_prompt_text: TextEdit = $InputSection/PromptsPanel/BasePromptText
@onready var _detail_prompt_text: TextEdit = $InputSection/PromptsPanel/DetailPromptText
@onready var _generate_button: Button = $InputSection/PromptsPanel/GenerateButton

# UI node references - Pipeline section
@onready var _stage1_preview: TextureRect = $PipelineSection/PipelinePreviews/Stage1/Preview
@onready var _stage2_preview: TextureRect = $PipelineSection/PipelinePreviews/Stage2/Preview
@onready var _stage3_preview: TextureRect = $PipelineSection/PipelinePreviews/Stage3/Preview
@onready var _progress_bar: ProgressBar = $PipelineSection/ProgressBar

# UI node references - Output section
@onready var _final_preview: TextureRect = $OutputSection/FinalPreview
@onready var _filename_edit: LineEdit = $OutputSection/SaveControls/FilenameEdit
@onready var _save_button: Button = $OutputSection/SaveControls/SaveButton


func _ready() -> void:
	_logger = PluginLogger.get_logger("MainPanel")
	_logger.info("Main panel ready")

	# Connect button signals - Template management
	_new_button.pressed.connect(_on_new_template_pressed)
	_edit_button.pressed.connect(_on_edit_template_pressed)
	_delete_button.pressed.connect(_on_delete_template_pressed)
	_template_dropdown.item_selected.connect(_on_template_selected)

	# Connect button signals - Generation
	_generate_button.pressed.connect(_on_generate_pressed)
	_select_image_button.pressed.connect(_on_select_image_pressed)
	_save_button.pressed.connect(_on_save_pressed)

	# Disable Save button initially (no result yet)
	_save_button.disabled = true

	# Create template editor dialog
	_template_editor = TemplateEditorDialog.instantiate()
	if _template_editor:
		add_child(_template_editor)
		_template_editor.template_saved.connect(_on_template_saved)

		# If initialize() was already called, initialize the editor now
		if _template_manager != null:
			_template_editor.initialize(_template_manager)

	# If initialize() was already called, refresh the template list now
	if _template_manager != null:
		_refresh_template_list()


## Called by plugin.gd when panel is initialized
func initialize(service_container: Variant) -> void:
	if _logger == null:
		_logger = PluginLogger.get_logger("MainPanel")
	_logger.info("Initializing main panel with services")

	# Get template_manager service
	var tm_result = service_container.get_service("template_manager")
	if tm_result.is_ok():
		_template_manager = tm_result.value
		_template_manager.template_created.connect(_on_template_changed)
		_template_manager.template_updated.connect(_on_template_changed)
		_template_manager.template_deleted.connect(_on_template_deleted)

		# Initialize template editor with manager (if _ready() already happened)
		if _template_editor != null:
			_template_editor.initialize(_template_manager)

		# Load templates (if _ready() already happened)
		_refresh_template_list()
	else:
		_logger.error("Failed to get template_manager", {"error": tm_result.error})

	# Get generation_pipeline service
	var gp_result = service_container.get_service("generation_pipeline")
	if gp_result.is_ok():
		_generation_pipeline = gp_result.value

		# Connect pipeline signals
		_generation_pipeline.progress_updated.connect(_on_pipeline_progress)
		_generation_pipeline.generation_complete.connect(_on_generation_complete)

		_logger.info("Connected to generation pipeline")
	else:
		_logger.error("Failed to get generation_pipeline", {"error": gp_result.error})

	# Get export_manager service
	var em_result = service_container.get_service("export_manager")
	if em_result.is_ok():
		_export_manager = em_result.value
		_logger.info("Got export_manager service")
	else:
		_logger.error("Failed to get export_manager", {"error": em_result.error})


## Refreshes the template dropdown list
func _refresh_template_list() -> void:
	if _template_manager == null:
		return

	# Check if UI nodes are ready yet
	if _template_dropdown == null:
		return

	_template_dropdown.clear()

	var result = _template_manager.list_templates()
	if result.is_err():
		_logger.error("Failed to list templates", {"error": result.error})
		return

	var templates: Array = result.value

	if templates.is_empty():
		_template_dropdown.add_item("No templates - click New")
		_edit_button.disabled = true
		_delete_button.disabled = true
		_generate_button.disabled = true
		return

	# Populate dropdown
	for template in templates:
		_template_dropdown.add_item(template.name)
		_template_dropdown.set_item_metadata(_template_dropdown.item_count - 1, template)

	# Select first template
	if _template_dropdown.item_count > 0:
		_template_dropdown.selected = 0
		_on_template_selected(0)

	_logger.info("Template list refreshed", {"count": templates.size()})


## Called when New Template button is pressed
func _on_new_template_pressed() -> void:
	_logger.debug("New template button pressed")
	if _template_editor:
		_template_editor.open_create()


## Called when Edit Template button is pressed
func _on_edit_template_pressed() -> void:
	if _selected_template == null:
		_logger.warn("No template selected for editing")
		return

	_logger.debug("Edit template button pressed", {"id": _selected_template.id})
	if _template_editor:
		_template_editor.open_edit(_selected_template)


## Called when Delete Template button is pressed
func _on_delete_template_pressed() -> void:
	if _selected_template == null:
		_logger.warn("No template selected for deletion")
		return

	_logger.debug("Delete template button pressed", {"id": _selected_template.id})

	# Show confirmation dialog
	var confirm_dialog := ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Delete template '%s'?\nThis cannot be undone." % _selected_template.name
	confirm_dialog.title = "Confirm Deletion"
	confirm_dialog.confirmed.connect(func(): _confirm_delete_template(_selected_template.id, confirm_dialog))
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()


## Confirms and executes template deletion
func _confirm_delete_template(template_id: String, dialog: ConfirmationDialog) -> void:
	var result = _template_manager.delete_template(template_id)

	if result.is_err():
		_logger.error("Failed to delete template", {"error": result.error})

	dialog.queue_free()


## Called when a template is selected from dropdown
func _on_template_selected(index: int) -> void:
	if index < 0 or index >= _template_dropdown.item_count:
		return

	_selected_template = _template_dropdown.get_item_metadata(index)

	if _selected_template == null:
		return

	_logger.debug("Template selected", {"id": _selected_template.id})

	# Load template data into UI
	_base_prompt_text.text = _selected_template.base_prompt
	# Detail prompt stays editable

	# Load reference image
	_load_reference_image(_selected_template.reference_image_path)

	# Enable buttons
	_edit_button.disabled = false
	_delete_button.disabled = false
	_generate_button.disabled = false


## Called when template is saved (created or updated)
func _on_template_saved(_template: Template) -> void:
	_logger.debug("Template saved, refreshing list")
	# Template list will be refreshed by signal handler


## Called when templates change (created or updated)
func _on_template_changed(_template: Template) -> void:
	_refresh_template_list()


## Called when a template is deleted
func _on_template_deleted(_template_id: String) -> void:
	_selected_template = null
	_refresh_template_list()


## Called when Generate button is pressed
func _on_generate_pressed() -> void:
	if _selected_template == null:
		_logger.warn("No template selected")
		_show_error("Please select a template first")
		return

	if _generation_pipeline == null:
		_logger.error("Generation pipeline not available")
		_show_error("Generation pipeline not initialized")
		return

	_logger.info("Starting generation", {"template": _selected_template.id})

	# Disable Generate button during generation
	_generate_button.disabled = true
	_generate_button.text = "Generating..."

	# Clear previous results
	_clear_pipeline_previews()
	_generated_result = null
	_save_button.disabled = true

	# Build generation settings
	var settings = GenerationSettings.new()
	settings.temperature = 1.0
	settings.detail_prompt = _detail_prompt_text.text

	# Start generation
	_generation_pipeline.generate(_selected_template, settings)


## Called when Select Image button is pressed
func _on_select_image_pressed() -> void:
	# TODO: Implement custom image selection (Iteration 11)
	_logger.debug("Select image pressed - not yet implemented")


## Called when pipeline reports progress
func _on_pipeline_progress(current_step: int, total_steps: int, message: String) -> void:
	_logger.debug("Pipeline progress", {"current": current_step, "total": total_steps, "message": message})

	# Update progress bar
	var percentage = (float(current_step) / float(total_steps)) * 100.0
	_progress_bar.value = percentage

	_logger.info("Progress: %s (%d/%d)" % [message, current_step, total_steps])


## Called when generation is complete
func _on_generation_complete(result: Variant) -> void:
	# Re-enable Generate button
	_generate_button.disabled = false
	_generate_button.text = "Generate"

	# Reset progress bar
	_progress_bar.value = 0

	if result.is_err():
		_logger.error("Generation failed", {"error": result.error})
		_show_error("Generation failed:\n%s" % result.error)
		return

	_logger.info("Generation completed successfully")

	# Store result
	_generated_result = result.value

	# Display pipeline stages
	_display_pipeline_result(_generated_result)

	# Enable Save button
	_save_button.disabled = false

	# Set default filename
	if _filename_edit.text.is_empty():
		_filename_edit.text = "generated_%s" % _selected_template.id


## Called when Save button is pressed
func _on_save_pressed() -> void:
	if _generated_result == null:
		_logger.warn("No result to save")
		return

	if _export_manager == null:
		_logger.error("Export manager not available")
		_show_error("Export manager not initialized")
		return

	var filename = _filename_edit.text
	if filename.is_empty():
		filename = "generated_asset"

	_logger.info("Saving result", {"filename": filename})

	# Export the final upscaled image
	var export_result = _export_manager.export_image(
		_generated_result.upscaled_image,
		filename,
		"res://"  # Save to project root
	)

	if export_result.is_err():
		_logger.error("Failed to save image", {"error": export_result.error})
		_show_error("Failed to save image:\n%s" % export_result.error)
		return

	_logger.info("Image saved successfully", {"path": export_result.value})
	# TODO: Show success message (Iteration 14)


## Loads and displays a reference image
func _load_reference_image(path: String) -> void:
	if path.is_empty():
		_ref_image_preview.texture = null
		return

	var image = Image.new()
	var err = image.load(path)

	if err != OK:
		_logger.error("Failed to load reference image", {"path": path, "error": err})
		_ref_image_preview.texture = null
		return

	var texture = ImageTexture.create_from_image(image)
	_ref_image_preview.texture = texture
	_logger.debug("Reference image loaded", {"path": path})


## Displays the generation result in pipeline previews
func _display_pipeline_result(gen_result: Variant) -> void:
	# Stage 1: Palette conformed
	if gen_result.conformed_image != null:
		_display_image_in_preview(_stage1_preview, gen_result.conformed_image)

	# Stage 2: AI Generated
	if gen_result.generated_image != null:
		_display_image_in_preview(_stage2_preview, gen_result.generated_image)

	# Stage 3: Pixelated
	if gen_result.pixelated_image != null:
		_display_image_in_preview(_stage3_preview, gen_result.pixelated_image)

	# Final: Upscaled
	if gen_result.upscaled_image != null:
		_display_image_in_preview(_final_preview, gen_result.upscaled_image)


## Displays an image in a TextureRect
func _display_image_in_preview(texture_rect: TextureRect, image: Image) -> void:
	if image == null:
		texture_rect.texture = null
		return

	var texture = ImageTexture.create_from_image(image)
	texture_rect.texture = texture


## Clears all pipeline preview images
func _clear_pipeline_previews() -> void:
	_stage1_preview.texture = null
	_stage2_preview.texture = null
	_stage3_preview.texture = null
	_final_preview.texture = null
	_progress_bar.value = 0


## Shows an error message to the user
func _show_error(message: String) -> void:
	# For now, just log - will add AcceptDialog in Iteration 14
	_logger.error("UI error", {"message": message})
	push_error(message)
