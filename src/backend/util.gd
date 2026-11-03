class_name Util
extends RefCounted

static func shuffle_with_rng(array: Array, rng: RandomNumberGenerator) -> void:
	for index: int in range(array.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary = array[index]
		array[index] = array[swap_index]
		array[swap_index] = temporary
