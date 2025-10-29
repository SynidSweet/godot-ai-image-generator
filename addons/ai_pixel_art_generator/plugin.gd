@tool
extends EditorPlugin

## AI Pixel Art Generator Plugin
##
## Main entry point for the Godot plugin that generates pixel art assets
## using Google's Gemini 2.5 Flash Image API (Nano Banana).
##
## Initializes all plugin services and manages their lifecycle.

const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")
const ServiceContainer = preload("res://addons/ai_pixel_art_generator/core/service_container.gd")
const TemplateManager = preload("res://addons/ai_pixel_art_generator/services/template_manager.gd")
const TemplateRepository = preload("res://addons/ai_pixel_art_generator/storage/template_repository.gd")
const PaletteRepository = preload("res://addons/ai_pixel_art_generator/storage/palette_repository.gd")
const SettingsRepository = preload("res://addons/ai_pixel_art_generator/storage/settings_repository.gd")
const ExportManager = preload("res://addons/ai_pixel_art_generator/storage/export_manager.gd")
const ImageProcessor = preload("res://addons/ai_pixel_art_generator/core/image_processor.gd")
const GenerationPipeline = preload("res://addons/ai_pixel_art_generator/core/generation_pipeline.gd")

const MainPanel = preload("res://addons/ai_pixel_art_generator/ui/main_panel.tscn")

var _container: ServiceContainer
var _logger: PluginLogger
var _main_panel: Control


func _enter_tree() -> void:
	"""Called when the plugin is activated in the editor."""
	_logger = PluginLogger.get_logger("Plugin")
	_logger.info("AI Pixel Art Generator: Initializing plugin")

	# Initialize service container
	_container = ServiceContainer.new()

	# Initialize and register services
	_initialize_services()

	# Initialize UI
	_initialize_ui()

	_logger.info("AI Pixel Art Generator: Plugin enabled", {
		"services": _container.get_service_count()
	})

	print("AI Pixel Art Generator: Plugin ready! 🎨")


func _exit_tree() -> void:
	"""Called when the plugin is deactivated in the editor."""
	_logger.info("AI Pixel Art Generator: Shutting down")

	# Cleanup UI
	_cleanup_ui()

	# Cleanup services
	_cleanup_services()

	if _container:
		_container.clear_all_services()
		_container = null

	_logger.info("AI Pixel Art Generator: Plugin disabled")
	print("AI Pixel Art Generator: Plugin disabled")


func _get_plugin_name() -> String:
	"""Returns the plugin name for display in the editor."""
	return "AI Pixel Art Generator"


## Initializes all plugin services
func _initialize_services() -> void:
	_logger.debug("Initializing services")

	# Storage layer
	var template_repo := TemplateRepository.new()
	var palette_repo := PaletteRepository.new()
	var settings_repo := SettingsRepository.new()
	var export_manager := ExportManager.new()

	_container.register_service("template_repository", template_repo)
	_container.register_service("palette_repository", palette_repo)
	_container.register_service("settings_repository", settings_repo)
	_container.register_service("export_manager", export_manager)

	# Processing layer
	var image_processor := ImageProcessor.new()
	_container.register_service("image_processor", image_processor)

	# Service layer
	var template_manager := TemplateManager.new()
	add_child(template_manager)  # Needs to be in tree for signals
	_container.register_service("template_manager", template_manager)

	# Pipeline layer
	var generation_pipeline := GenerationPipeline.new()
	add_child(generation_pipeline)  # Needs to be in tree for signals
	_container.register_service("generation_pipeline", generation_pipeline)

	_logger.info("Services initialized", {"count": _container.get_service_count()})


## Cleans up services on plugin disable
func _cleanup_services() -> void:
	_logger.debug("Cleaning up services")

	# Remove services from scene tree
	var template_manager_result := _container.get_service("template_manager")
	if template_manager_result.is_ok():
		var manager = template_manager_result.value
		if is_instance_valid(manager):
			manager.queue_free()

	var pipeline_result := _container.get_service("generation_pipeline")
	if pipeline_result.is_ok():
		var pipeline = pipeline_result.value
		if is_instance_valid(pipeline):
			pipeline.queue_free()


## Initializes the UI panel
func _initialize_ui() -> void:
	_logger.debug("Initializing UI")

	# Instantiate main panel
	_main_panel = MainPanel.instantiate()

	# Initialize with service container
	if _main_panel.has_method("initialize"):
		_main_panel.initialize(_container)

	# Add to bottom panel in editor
	add_control_to_bottom_panel(_main_panel, "AI Pixel Art")

	_logger.info("UI initialized")


## Cleans up UI on plugin disable
func _cleanup_ui() -> void:
	_logger.debug("Cleaning up UI")

	if _main_panel:
		remove_control_from_bottom_panel(_main_panel)
		_main_panel.queue_free()
		_main_panel = null


## Gets a service by name (convenience method)
##
## Returns the service or null if not found
func get_service(service_name: String) -> Variant:
	var result := _container.get_service(service_name)
	if result.is_ok():
		return result.value
	return null

