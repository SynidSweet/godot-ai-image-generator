extends GutTest

## Tests for ServiceContainer
##
## ServiceContainer manages plugin services and dependencies.
## Provides centralized service registry for dependency injection.

const ServiceContainer = preload("res://addons/ai_pixel_art_generator/core/service_container.gd")
const Result = preload("res://addons/ai_pixel_art_generator/core/result.gd")

var container: ServiceContainer


func before_each() -> void:
	container = ServiceContainer.new()


## Initialization Tests


func test_container_initializes() -> void:
	assert_not_null(container, "Container should initialize")


func test_container_starts_empty() -> void:
	assert_false(container.has_service("anything"), "Should start empty")


## Register Service Tests


func test_register_service() -> void:
	var service := Node.new()
	var result := container.register_service("test_service", service)

	assert_true(result.is_ok(), "Should register service")
	assert_true(container.has_service("test_service"), "Service should be registered")

	service.queue_free()


func test_register_null_service_fails() -> void:
	var result := container.register_service("test", null)
	assert_true(result.is_err(), "Should reject null service")


func test_register_empty_name_fails() -> void:
	var service := Node.new()
	var result := container.register_service("", service)

	assert_true(result.is_err(), "Should reject empty name")
	service.queue_free()


func test_register_duplicate_name_fails() -> void:
	var service1 := Node.new()
	var service2 := Node.new()

	var result1 := container.register_service("duplicate", service1)
	assert_true(result1.is_ok(), "First should succeed")

	var result2 := container.register_service("duplicate", service2)
	assert_true(result2.is_err(), "Second should fail")

	service1.queue_free()
	service2.queue_free()


## Get Service Tests


func test_get_service() -> void:
	var service := Node.new()
	service.name = "TestService"

	var _reg := container.register_service("test_service", service)

	var result := container.get_service("test_service")
	assert_true(result.is_ok(), "Should get service")
	assert_eq(result.value, service, "Should return same service")

	service.queue_free()


func test_get_nonexistent_service_fails() -> void:
	var result := container.get_service("nonexistent")
	assert_true(result.is_err(), "Should fail to get nonexistent service")


func test_get_empty_name_fails() -> void:
	var result := container.get_service("")
	assert_true(result.is_err(), "Should reject empty name")


## Service Existence Tests


func test_has_service() -> void:
	var service := Node.new()
	var _reg := container.register_service("test", service)

	assert_true(container.has_service("test"), "Should have service")
	assert_false(container.has_service("nonexistent"), "Should not have nonexistent")

	service.queue_free()


## Clear Services Test


func test_clear_all_services() -> void:
	var service1 := Node.new()
	var service2 := Node.new()

	var _r1 := container.register_service("s1", service1)
	var _r2 := container.register_service("s2", service2)

	container.clear_all_services()

	assert_false(container.has_service("s1"), "Should clear s1")
	assert_false(container.has_service("s2"), "Should clear s2")

	service1.queue_free()
	service2.queue_free()


## List Services Test


func test_list_service_names() -> void:
	var service1 := Node.new()
	var service2 := Node.new()

	var _r1 := container.register_service("alpha", service1)
	var _r2 := container.register_service("beta", service2)

	var names := container.list_service_names()
	assert_eq(names.size(), 2, "Should have 2 services")
	assert_has(names, "alpha", "Should have alpha")
	assert_has(names, "beta", "Should have beta")

	service1.queue_free()
	service2.queue_free()
