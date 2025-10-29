@tool
extends VBoxContainer

## Main Panel UI Controller
##
## Main UI panel for the AI Pixel Art Generator plugin.
## Manages template selection, generation workflow, and output display.

const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")
const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
const TemplateEditorDialog = preload("res://addons/ai_pixel_art_generator/ui/dialogs/template_editor_dialog.tscn")

var _logger: PluginLogger
var _template_manager: Variant = null
var _generation_pipeline: Variant = null
var _selected_template: Template = null
var _template_editor: ConfirmationDialog = null

# UI node references
@onready var _template_dropdown: OptionButton = $TemplateSelector/TemplateDropdown
@onready var _new_button: Button = $TemplateSelector/NewButton
@onready var _edit_button: Button = $TemplateSelector/EditButton
@onready var _delete_button: Button = $TemplateSelector/DeleteButton
@onready var _base_prompt_text: TextEdit = $InputSection/PromptsPanel/BasePromptText
@onready var _detail_prompt_text: TextEdit = $InputSection/PromptsPanel/DetailPromptText
@onready var _generate_button: Button = $InputSection/PromptsPanel/GenerateButton


func _ready() -> void:
	_logger = PluginLogger.get_logger("MainPanel")
	_logger.info("Main panel ready")

	# Connect button signals
	_new_button.pressed.connect(_on_new_template_pressed)
	_edit_button.pressed.connect(_on_edit_template_pressed)
	_delete_button.pressed.connect(_on_delete_template_pressed)
	_template_dropdown.item_selected.connect(_on_template_selected)
	_generate_button.pressed.connect(_on_generate_pressed)

	# Create template editor dialog
	_template_editor = TemplateEditorDialog.instantiate()
	add_child(_template_editor)
	_template_editor.template_saved.connect(_on_template_saved)


## Called by plugin.gd when panel is initialized
func initialize(service_container: Variant) -> void:
	_logger.info("Initializing main panel with services")

	# Get services
	var tm_result = service_container.get_service("template_manager")
	if tm_result.is_ok():
		_template_manager = tm_result.value
		_template_manager.template_created.connect(_on_template_changed)
		_template_manager.template_updated.connect(_on_template_changed)
		_template_manager.template_deleted.connect(_on_template_deleted)

		# Initialize template editor with manager
		if _template_editor and _template_editor.has_method("initialize"):
			_template_editor.initialize(_template_manager)

		# Load templates
		_refresh_template_list()
	else:
		_logger.error("Failed to get template_manager", {"error": tm_result.error})

	var gp_result = service_container.get_service("generation_pipeline")
	if gp_result.is_ok():
		_generation_pipeline = gp_result.value
	else:
		_logger.error("Failed to get generation_pipeline", {"error": gp_result.error})


## Refreshes the template dropdown list
func _refresh_template_list() -> void:
	if _template_manager == null:
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
	_logger.info("Generate button pressed")
	# TODO: Implement in Iteration 10
	push_warning("Generation not yet implemented - Iteration 10")
