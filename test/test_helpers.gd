extends Node

## Test Helpers
##
## Common utilities and helper functions for tests.


static func create_test_image(width: int, height: int, color: Color) -> Image:
	"""Creates a test image filled with a single color."""
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


static func create_test_palette(colors: Array[Color]) -> Array[Color]:
	"""Creates a test color palette from an array of colors."""
	return colors


static func images_are_equal(image1: Image, image2: Image) -> bool:
	"""Compares two images pixel by pixel."""
	if image1 == null or image2 == null:
		return false

	if image1.get_width() != image2.get_width() or image1.get_height() != image2.get_height():
		return false

	for y in range(image1.get_height()):
		for x in range(image1.get_width()):
			if image1.get_pixel(x, y) != image2.get_pixel(x, y):
				return false

	return true
