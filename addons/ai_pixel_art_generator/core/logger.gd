class_name Logger

## Logger for Consistent Logging
##
## Provides structured logging with levels (DEBUG, INFO, WARN, ERROR)
## and context for better debugging and monitoring.
##
## Usage:
##   var logger := Logger.new("MyClass")
##   logger.info("Operation completed")
##   logger.warn("Something unexpected happened")
##   logger.error("Operation failed", {"reason": "network error"})
##
## Or use singleton pattern:
##   var logger := Logger.get_logger("MyClass")

const LOG_LEVEL_DEBUG := "DEBUG"
const LOG_LEVEL_INFO := "INFO"
const LOG_LEVEL_WARN := "WARN"
const LOG_LEVEL_ERROR := "ERROR"

var context: String = ""
var debug_enabled: bool = false

# Allows overriding print function for testing
var _print_func: Callable = func(msg: String): print(msg)

# Global logger registry for singleton pattern
static var _loggers: Dictionary = {}


func _init(ctx: String = "Main") -> void:
	context = ctx


## Get or create a logger for the given context (singleton pattern)
static func get_logger(ctx: String) -> Logger:
	if not _loggers.has(ctx):
		_loggers[ctx] = Logger.new(ctx)
	return _loggers[ctx]


## Log a debug message (only if debug_enabled is true)
func debug(message: String, data: Variant = null) -> void:
	if debug_enabled:
		_log(LOG_LEVEL_DEBUG, message, data)


## Log an info message
func info(message: String, data: Variant = null) -> void:
	_log(LOG_LEVEL_INFO, message, data)


## Log a warning message
func warn(message: String, data: Variant = null) -> void:
	_log(LOG_LEVEL_WARN, message, data)


## Log an error message
func error(message: String, data: Variant = null) -> void:
	_log(LOG_LEVEL_ERROR, message, data)


## Internal logging implementation
func _log(level: String, message: String, data: Variant = null) -> void:
	var formatted := _format_message(level, message)

	if data != null:
		formatted += " | Data: " + str(data)

	_print_func.call(formatted)


## Format log message with level, context, and timestamp
func _format_message(level: String, message: String) -> String:
	var time := Time.get_datetime_dict_from_system()
	var timestamp := "%02d:%02d:%02d" % [time.hour, time.minute, time.second]

	return "[%s] [%s] [%s] %s" % [timestamp, level, context, message]
