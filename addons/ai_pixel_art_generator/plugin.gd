@tool
extends EditorPlugin

## AI Pixel Art Generator Plugin
##
## Main entry point for the Godot plugin that generates pixel art assets
## using Google's Gemini 2.5 Flash Image API (Nano Banana).
##
## This plugin will be expanded in future iterations to include:
## - Service initialization
## - UI panel registration
## - Plugin lifecycle management


func _enter_tree() -> void:
	"""Called when the plugin is activated in the editor."""
	print("AI Pixel Art Generator: Plugin enabled")
	# TODO: Initialize services and UI in future iterations


func _exit_tree() -> void:
	"""Called when the plugin is deactivated in the editor."""
	print("AI Pixel Art Generator: Plugin disabled")
	# TODO: Cleanup services and UI in future iterations


func _get_plugin_name() -> String:
	"""Returns the plugin name for display in the editor."""
	return "AI Pixel Art Generator"
