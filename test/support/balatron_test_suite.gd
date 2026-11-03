class_name BalatronTestSuite
extends GdUnitTestSuite


func assert_eq(current: Variant, expected: Variant, message := "") -> void:
	var assertion := assert_that(current)
	if not message.is_empty():
		assertion.append_failure_message(message)
	assertion.is_equal(expected)


func assert_true(current: bool) -> void:
	assert_bool(current).is_true()


func assert_false(current: bool) -> void:
	assert_bool(current).is_false()


func assert_between(current: int, minimum: int, maximum: int) -> void:
	assert_int(current).is_between(minimum, maximum)


func assert_not_null(current: Variant) -> void:
	assert_that(current).is_not_null()


func assert_not_same(current: Object, expected: Object) -> void:
	assert_object(current).is_not_same(expected)


func assert_has(current: Variant, expected: Variant) -> void:
	assert_array(current, false).contains(expected)
