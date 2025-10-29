class_name Result

## Result Type for Error Handling
##
## A Result represents either success (Ok) or failure (Err).
## This pattern provides explicit error handling without exceptions.
##
## Usage:
##   var result := some_function_that_can_fail()
##   if result.is_ok():
##       print("Success: ", result.value)
##   else:
##       print("Error: ", result.error)
##
## Or using unwrap:
##   var value := result.unwrap_or(default_value)
##
## Or chaining:
##   var final_result := result
##       .map(func(x): return x * 2)
##       .and_then(func(x): return another_operation(x))

var value: Variant = null
var error: String = ""
var _is_ok: bool = false


## Creates a successful Result containing a value
static func ok(val: Variant) -> Result:
	var result := Result.new()
	result.value = val
	result._is_ok = true
	return result


## Creates a failed Result containing an error message
static func err(error_message: String) -> Result:
	var result := Result.new()
	result.error = error_message
	result._is_ok = false
	return result


## Returns true if this Result represents success
func is_ok() -> bool:
	return _is_ok


## Returns true if this Result represents failure
func is_err() -> bool:
	return not _is_ok


## Unwraps the Result, returning the value on success or null on error
func unwrap() -> Variant:
	if is_ok():
		return value
	return null


## Unwraps the Result, returning the value on success or a default value on error
func unwrap_or(default_value: Variant) -> Variant:
	if is_ok():
		return value
	return default_value


## Maps the success value through a transformation function
## If this Result is an error, the error is propagated unchanged
func map(transform: Callable) -> Result:
	if is_err():
		return Result.err(error)
	return Result.ok(transform.call(value))


## Maps the error message through a transformation function
## If this Result is a success, the value is propagated unchanged
func map_error(transform: Callable) -> Result:
	if is_ok():
		return Result.ok(value)
	return Result.err(transform.call(error))


## Chains this Result with another operation that returns a Result
## If this Result is an error, the error is propagated without calling the function
## If this Result is ok, calls the function with the value and returns its Result
func and_then(next_operation: Callable) -> Result:
	if is_err():
		return Result.err(error)
	return next_operation.call(value)


## String representation for debugging
func _to_string() -> String:
	if is_ok():
		return "Result.Ok(%s)" % str(value)
	else:
		return "Result.Err(%s)" % error
