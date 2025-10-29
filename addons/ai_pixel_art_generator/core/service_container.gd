class_name ServiceContainer

## Service Container
##
## Centralized registry for plugin services. Provides dependency injection
## and service lifecycle management.
##
## Usage:
##   var container := ServiceContainer.new()
##   container.register_service("template_manager", template_manager)
##   var result := container.get_service("template_manager")
##   if result.is_ok():
##       var manager = result.value

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")
const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")

var _services: Dictionary = {}
var _logger: PluginLogger


func _init() -> void:
	_logger = PluginLogger.get_logger("ServiceContainer")


## Registers a service in the container
##
## Parameters:
##   service_name: Unique name for the service
##   service: Service instance (must be a Node or Object)
##
## Returns:
##   Result: Ok if registered, Err if failed
func register_service(service_name: String, service: Variant) -> Result:
	if service_name.is_empty():
		return Result.err("Service name cannot be empty")

	if service == null:
		return Result.err("Service cannot be null")

	if _services.has(service_name):
		return Result.err("Service '%s' already registered" % service_name)

	_services[service_name] = service
	_logger.debug("Service registered", {"name": service_name})

	return Result.ok(true)


## Gets a service from the container
##
## Parameters:
##   service_name: Name of the service to retrieve
##
## Returns:
##   Result<Variant>: Service instance if found, error otherwise
func get_service(service_name: String) -> Result:
	if service_name.is_empty():
		return Result.err("Service name cannot be empty")

	if not _services.has(service_name):
		return Result.err("Service '%s' not found" % service_name)

	return Result.ok(_services[service_name])


## Checks if a service is registered
##
## Parameters:
##   service_name: Name of the service
##
## Returns:
##   bool: True if service exists, false otherwise
func has_service(service_name: String) -> bool:
	return _services.has(service_name)


## Removes all services from the container
func clear_all_services() -> void:
	_logger.debug("Clearing all services", {"count": _services.size()})
	_services.clear()


## Gets list of all registered service names
##
## Returns:
##   Array[String]: Array of service names
func list_service_names() -> Array[String]:
	var names: Array[String] = []
	for key in _services.keys():
		names.append(key)
	return names


## Gets the number of registered services
##
## Returns:
##   int: Number of services
func get_service_count() -> int:
	return _services.size()
