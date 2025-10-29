@tool
extends AcceptDialog

## Settings Dialog
##
## Dialog for configuring plugin settings including API key,
## generation parameters, and export preferences.

const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

var _settings_repository: Variant = null
var _palette_repository: Variant = null
var _logger: PluginLogger

# Aspect ratio mapping
const ASPECT_RATIOS := ["1:1", "16:9", "9:16", "4:3", "3:4"]

# UI node references
@onready var _api_key_edit: LineEdit = $Content/APIKeyField/LineEdit
@onready var _temperature_spin: SpinBox = $Content/TemperatureField/SpinBox
@onready var _aspect_ratio_option: OptionButton = $Content/AspectRatioField/OptionButton
@onready var _export_path_edit: LineEdit = $Content/ExportPathField/PathContainer/LineEdit
@onready var _browse_button: Button = $Content/ExportPathField/PathContainer/BrowseButton
@onready var _default_palette_option: OptionButton = $Content/DefaultPaletteField/OptionButton
@onready var _file_dialog: FileDialog = $FileDialog


func _ready() -> void:
	_logger = PluginLogger.get_logger("SettingsDialog")

	# Connect signals
	confirmed.connect(_on_confirmed)
	_browse_button.pressed.connect(_on_browse_pressed)
	_file_dialog.dir_selected.connect(_on_dir_selected)


## Initializes the dialog with repositories
func initialize(settings_repository: Variant, palette_repository: Variant) -> void:
	_settings_repository = settings_repository
	_palette_repository = palette_repository

	# Populate palette dropdown
	_populate_palette_options()

	_logger.debug("Dialog initialized")


## Opens the settings dialog and loads current settings
func open_settings() -> void:
	_load_settings()
	popup_centered()
	_logger.debug("Opened settings dialog")


## Loads current settings from repository
func _load_settings() -> void:
	if _settings_repository == null:
		_logger.warn("Settings repository not initialized")
		return

	# Load API key
	var api_key_result = _settings_repository.load_api_key()
	if api_key_result.is_ok():
		_api_key_edit.text = api_key_result.value
	else:
		_api_key_edit.text = ""

	# Load temperature
	var temp = _settings_repository.load_setting("generation", "temperature", 1.0)
	_temperature_spin.value = temp

	# Load aspect ratio
	var aspect_ratio = _settings_repository.load_setting("generation", "aspect_ratio", "1:1")
	var aspect_idx = ASPECT_RATIOS.find(aspect_ratio)
	if aspect_idx >= 0:
		_aspect_ratio_option.selected = aspect_idx
	else:
		_aspect_ratio_option.selected = 0

	# Load export path
	var export_path = _settings_repository.load_setting("export", "default_path", "res://")
	_export_path_edit.text = export_path

	# Load default palette
	var default_palette = _settings_repository.load_setting("generation", "default_palette", "db32")
	_select_palette(default_palette)

	_logger.debug("Settings loaded")


## Saves settings to repository
func _save_settings() -> void:
	if _settings_repository == null:
		_logger.error("Cannot save: settings repository not initialized")
		return

	# Save API key
	var api_key = _api_key_edit.text.strip_edges()
	if not api_key.is_empty():
		var result = _settings_repository.save_api_key(api_key)
		if result.is_err():
			_logger.error("Failed to save API key", {"error": result.error})
	else:
		_logger.warn("API key is empty - not saving")

	# Save temperature
	_settings_repository.save_setting("generation", "temperature", _temperature_spin.value)

	# Save aspect ratio
	var selected_ratio = ASPECT_RATIOS[_aspect_ratio_option.selected]
	_settings_repository.save_setting("generation", "aspect_ratio", selected_ratio)

	# Save export path
	_settings_repository.save_setting("export", "default_path", _export_path_edit.text)

	# Save default palette
	var palette_text = _default_palette_option.get_item_text(_default_palette_option.selected)
	_settings_repository.save_setting("generation", "default_palette", palette_text)

	_logger.info("Settings saved", {
		"has_api_key": not api_key.is_empty(),
		"temperature": _temperature_spin.value,
		"aspect_ratio": selected_ratio
	})


## Populates the palette dropdown from PaletteRepository
func _populate_palette_options() -> void:
	if _palette_repository == null:
		return

	_default_palette_option.clear()

	var result = _palette_repository.list_available_palettes()
	if result.is_err():
		_logger.error("Failed to list palettes", {"error": result.error})
		# Add fallback
		_default_palette_option.add_item("db32")
		return

	var palettes: Array = result.value
	for palette_name in palettes:
		_default_palette_option.add_item(palette_name)

	_logger.debug("Populated palette options", {"count": palettes.size()})


## Selects a palette by name in the dropdown
func _select_palette(palette_name: String) -> void:
	for i in range(_default_palette_option.item_count):
		if _default_palette_option.get_item_text(i) == palette_name:
			_default_palette_option.selected = i
			return
	# If not found, select first
	if _default_palette_option.item_count > 0:
		_default_palette_option.selected = 0


## Called when OK button is pressed
func _on_confirmed() -> void:
	_save_settings()


## Called when Browse button is pressed
func _on_browse_pressed() -> void:
	_file_dialog.current_dir = _export_path_edit.text
	_file_dialog.popup_centered()


## Called when directory is selected in file dialog
func _on_dir_selected(path: String) -> void:
	_export_path_edit.text = path
	_logger.debug("Export path selected", {"path": path})
