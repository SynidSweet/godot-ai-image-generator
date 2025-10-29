extends GutTest

## Tests for the Result class
##
## The Result class is used for error handling throughout the codebase.
## It represents either a successful result with a value or a failure with an error message.

const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")


func test_ok_creates_success_result() -> void:
	var result := Result.ok("test_value")

	assert_true(result.is_ok(), "Result should be ok")
	assert_false(result.is_err(), "Result should not be error")
	assert_eq(result.value, "test_value", "Result should contain the value")


func test_ok_with_null_value() -> void:
	var result := Result.ok(null)

	assert_true(result.is_ok(), "Result should be ok even with null value")
	assert_null(result.value, "Result value should be null")


func test_err_creates_error_result() -> void:
	var result := Result.err("Something went wrong")

	assert_true(result.is_err(), "Result should be error")
	assert_false(result.is_ok(), "Result should not be ok")
	assert_eq(result.error, "Something went wrong", "Result should contain the error message")


func test_err_with_empty_message() -> void:
	var result := Result.err("")

	assert_true(result.is_err(), "Result should be error even with empty message")
	assert_eq(result.error, "", "Error message should be empty string")


func test_unwrap_returns_value_on_success() -> void:
	var result := Result.ok(42)

	assert_eq(result.unwrap(), 42, "Unwrap should return the value")


func test_unwrap_returns_null_on_error() -> void:
	var result := Result.err("Error")

	assert_null(result.unwrap(), "Unwrap should return null on error")


func test_unwrap_or_returns_value_on_success() -> void:
	var result := Result.ok("success")

	assert_eq(result.unwrap_or("default"), "success", "unwrap_or should return the value")


func test_unwrap_or_returns_default_on_error() -> void:
	var result := Result.err("Error")

	assert_eq(result.unwrap_or("default"), "default", "unwrap_or should return default on error")


func test_map_transforms_success_value() -> void:
	var result := Result.ok(5)
	var mapped := result.map(func(x): return x * 2)

	assert_true(mapped.is_ok(), "Mapped result should be ok")
	assert_eq(mapped.value, 10, "Mapped value should be transformed")


func test_map_does_not_transform_error() -> void:
	var result := Result.err("Error")
	var mapped := result.map(func(x): return x * 2)

	assert_true(mapped.is_err(), "Mapped result should still be error")
	assert_eq(mapped.error, "Error", "Error message should be unchanged")


func test_map_error_transforms_error_message() -> void:
	var result := Result.err("original error")
	var mapped := result.map_error(func(e): return "wrapped: " + e)

	assert_true(mapped.is_err(), "Mapped result should still be error")
	assert_eq(mapped.error, "wrapped: original error", "Error message should be transformed")


func test_map_error_does_not_transform_success() -> void:
	var result := Result.ok("value")
	var mapped := result.map_error(func(e): return "wrapped: " + e)

	assert_true(mapped.is_ok(), "Mapped result should still be ok")
	assert_eq(mapped.value, "value", "Value should be unchanged")


func test_and_then_chains_success() -> void:
	var result := Result.ok(5)
	var chained := result.and_then(func(x): return Result.ok(x * 2))

	assert_true(chained.is_ok(), "Chained result should be ok")
	assert_eq(chained.value, 10, "Chained value should be transformed")


func test_and_then_propagates_error() -> void:
	var result := Result.err("First error")
	var chained := result.and_then(func(x): return Result.ok(x * 2))

	assert_true(chained.is_err(), "Chained result should be error")
	assert_eq(chained.error, "First error", "Error should be propagated")


func test_and_then_can_return_error() -> void:
	var result := Result.ok(5)
	var chained := result.and_then(func(x): return Result.err("New error"))

	assert_true(chained.is_err(), "Chained result should be error")
	assert_eq(chained.error, "New error", "New error should be returned")


func test_result_with_dictionary_value() -> void:
	var data := {"key": "value", "count": 42}
	var result := Result.ok(data)

	assert_true(result.is_ok(), "Result should be ok")
	assert_eq(result.value["key"], "value", "Dictionary should be preserved")
	assert_eq(result.value["count"], 42, "Dictionary should be preserved")


func test_result_with_array_value() -> void:
	var arr := [1, 2, 3, 4, 5]
	var result := Result.ok(arr)

	assert_true(result.is_ok(), "Result should be ok")
	assert_eq(result.value.size(), 5, "Array should be preserved")
	assert_eq(result.value[0], 1, "Array elements should be preserved")


func test_result_with_object_value() -> void:
	var obj := Node.new()
	var result := Result.ok(obj)

	assert_true(result.is_ok(), "Result should be ok")
	assert_not_null(result.value, "Object should be preserved")
	assert_eq(result.value, obj, "Object reference should be preserved")

	obj.free()
