extends GutTest

## Tests for the PluginLogger class
##
## The PluginLogger class provides consistent logging throughout the codebase
## with different log levels and context.

const PluginLogger = preload("res://addons/ai_pixel_art_generator/core/logger.gd")


var logger: PluginLogger
var test_output: Array[String] = []


func before_each() -> void:
	test_output.clear()
	logger = PluginLogger.new("TestModule")
	# Replace print function with test capture
	logger._print_func = func(msg: String): test_output.append(msg)


func after_each() -> void:
	logger = null
	test_output.clear()


func test_logger_has_context() -> void:
	assert_eq(logger.context, "TestModule", "Logger should store context")


func test_info_logs_message() -> void:
	logger.info("Test message")

	assert_eq(test_output.size(), 1, "Should log one message")
	assert_string_contains(test_output[0], "INFO", "Should contain INFO level")
	assert_string_contains(test_output[0], "TestModule", "Should contain context")
	assert_string_contains(test_output[0], "Test message", "Should contain message")


func test_warn_logs_message() -> void:
	logger.warn("Warning message")

	assert_eq(test_output.size(), 1, "Should log one message")
	assert_string_contains(test_output[0], "WARN", "Should contain WARN level")
	assert_string_contains(test_output[0], "Warning message", "Should contain message")


func test_error_logs_message() -> void:
	logger.error("Error message")

	assert_eq(test_output.size(), 1, "Should log one message")
	assert_string_contains(test_output[0], "ERROR", "Should contain ERROR level")
	assert_string_contains(test_output[0], "Error message", "Should contain message")


func test_debug_logs_message_when_enabled() -> void:
	logger.debug_enabled = true
	logger.debug("Debug message")

	assert_eq(test_output.size(), 1, "Should log one message when debug enabled")
	assert_string_contains(test_output[0], "DEBUG", "Should contain DEBUG level")


func test_debug_does_not_log_when_disabled() -> void:
	logger.debug_enabled = false
	logger.debug("Debug message")

	assert_eq(test_output.size(), 0, "Should not log when debug disabled")


func test_log_with_data() -> void:
	var data := {"key": "value", "count": 42}
	logger.info("Message with data", data)

	assert_eq(test_output.size(), 1, "Should log one message")
	assert_string_contains(test_output[0], "Message with data", "Should contain message")
	assert_string_contains(test_output[0], "key", "Should contain data keys")
	assert_string_contains(test_output[0], "value", "Should contain data values")


func test_global_logger_singleton() -> void:
	var global1 := PluginLogger.get_logger("Global")
	var global2 := PluginLogger.get_logger("Global")

	assert_eq(global1, global2, "get_logger should return same instance for same context")


func test_different_contexts_have_different_loggers() -> void:
	var logger1 := PluginLogger.get_logger("Context1")
	var logger2 := PluginLogger.get_logger("Context2")

	assert_ne(logger1, logger2, "Different contexts should have different loggers")
	assert_eq(logger1.context, "Context1", "Logger 1 should have correct context")
	assert_eq(logger2.context, "Context2", "Logger 2 should have correct context")


func test_format_message_structure() -> void:
	var formatted := logger._format_message("INFO", "Test")

	assert_string_contains(formatted, "[", "Should contain bracket")
	assert_string_contains(formatted, "INFO", "Should contain level")
	assert_string_contains(formatted, "TestModule", "Should contain context")
	assert_string_contains(formatted, "Test", "Should contain message")


func test_empty_message_still_logs() -> void:
	logger.info("")

	assert_eq(test_output.size(), 1, "Should log even with empty message")


func test_null_data_does_not_crash() -> void:
	logger.info("Message", null)

	assert_eq(test_output.size(), 1, "Should log without crashing")


func test_multiple_log_calls() -> void:
	logger.info("First")
	logger.warn("Second")
	logger.error("Third")

	assert_eq(test_output.size(), 3, "Should log all messages")
