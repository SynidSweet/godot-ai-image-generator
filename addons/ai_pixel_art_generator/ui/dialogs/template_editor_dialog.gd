@tool
extends ConfirmationDialog

## Template Editor Dialog
##
## Dialog for creating and editing templates.
## Handles form validation and emits signals on save.

const Template = preload("res://addons/ai_pixel_art_generator/models/template.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

signal template_saved(template)

enum EditorMode {
	CREATE,  ## Creating a new template
	EDIT     ## Editing existing template
}

var _mode: EditorMode = EditorMode.CREATE
var _original_template: Template = null
var _template_manager: Variant = null
var _logger: PluginLogger

# UI node references
@onready var _id_edit: LineEdit = $Content/IDField/LineEdit
@onready var _name_edit: LineEdit = $Content/NameField/LineEdit
@onready var _ref_image_path: LineEdit = $Content/ReferenceImageField/PathEdit
@onready var _browse_button: Button = $Content/ReferenceImageField/BrowseButton
@onready var _base_prompt: TextEdit = $Content/BasePromptField/TextEdit
@onready var _width_spin: SpinBox = $Content/TargetResolutionField/WidthSpinBox
@onready var _height_spin: SpinBox = $Content/TargetResolutionField/HeightSpinBox
@onready var _palette_option: OptionButton = $Content/PaletteField/OptionButton
@onready var _file_dialog: FileDialog = $FileDialog


func _ready() -> void:
	_logger = PluginLogger.get_logger("TemplateEditorDialog")

	# Connect signals
	confirmed.connect(_on_confirmed)
	_browse_button.pressed.connect(_on_browse_pressed)
	_file_dialog.file_selected.connect(_on_file_selected)


## Initializes the dialog with template manager
func initialize(template_manager: Variant) -> void:
	_template_manager = template_manager
	_logger.debug("Dialog initialized")


## Opens dialog in CREATE mode
func open_create() -> void:
	_mode = EditorMode.CREATE
	_original_template = null

	title = "Create New Template"
	_clear_fields()
	_id_edit.editable = true  # Can set ID when creating

	popup_centered()
	_logger.debug("Opened in CREATE mode")


## Opens dialog in EDIT mode
func open_edit(template: Template) -> void:
	_mode = EditorMode.EDIT
	_original_template = template

	title = "Edit Template"
	_load_template_data(template)
	_id_edit.editable = false  # Cannot change ID when editing

	popup_centered()
	_logger.debug("Opened in EDIT mode", {"id": template.id})


## Clears all form fields
func _clear_fields() -> void:
	_id_edit.text = ""
	_name_edit.text = ""
	_ref_image_path.text = ""
	_base_prompt.text = ""
	_width_spin.value = 32
	_height_spin.value = 32
	_palette_option.selected = 0


## Loads template data into form fields
func _load_template_data(template: Template) -> void:
	_id_edit.text = template.id
	_name_edit.text = template.name
	_ref_image_path.text = template.reference_image_path
	_base_prompt.text = template.base_prompt
	_width_spin.value = template.target_resolution.x
	_height_spin.value = template.target_resolution.y

	# Set palette (for now just use first option, will be enhanced later)
	_palette_option.selected = 0


## Called when OK button is pressed
func _on_confirmed() -> void:
	if _mode == EditorMode.CREATE:
		_create_template()
	else:
		_update_template()


## Creates a new template
func _create_template() -> void:
	var result = _template_manager.create_template(
		_id_edit.text,
		_name_edit.text,
		_ref_image_path.text,
		_base_prompt.text,
		Vector2i(_width_spin.value, _height_spin.value),
		_get_selected_palette()
	)

	if result.is_ok():
		_logger.info("Template created", {"id": _id_edit.text})
		template_saved.emit(result.value)
	else:
		_logger.error("Failed to create template", {"error": result.error})
		_show_error("Failed to create template:\n%s" % result.error)


## Updates an existing template
func _update_template() -> void:
	if _original_template == null:
		_logger.error("Cannot update: no original template")
		return

	# Update template object
	_original_template.name = _name_edit.text
	_original_template.reference_image_path = _ref_image_path.text
	_original_template.base_prompt = _base_prompt.text
	_original_template.target_resolution = Vector2i(_width_spin.value, _height_spin.value)
	_original_template.palette_name = _get_selected_palette()

	var result = _template_manager.update_template(_original_template)

	if result.is_ok():
		_logger.info("Template updated", {"id": _original_template.id})
		template_saved.emit(_original_template)
	else:
		_logger.error("Failed to update template", {"error": result.error})
		_show_error("Failed to update template:\n%s" % result.error)


## Called when Browse button is pressed
func _on_browse_pressed() -> void:
	_file_dialog.popup_centered()


## Called when file is selected in file dialog
func _on_file_selected(path: String) -> void:
	_ref_image_path.text = path
	_logger.debug("Image selected", {"path": path})


## Gets the selected palette name
func _get_selected_palette() -> String:
	var idx := _palette_option.selected
	if idx >= 0:
		return _palette_option.get_item_text(idx)
	return "db32"


## Shows an error message
func _show_error(message: String) -> void:
	# For now, just log - will add AcceptDialog in Iteration 14
	_logger.error("Dialog error", {"message": message})
	push_error(message)
