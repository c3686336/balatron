class_name Tile
extends RefCounted

var value: int


func _init(p_value: int) -> void:
	assert(p_value >= 1 and p_value <= 9, "Tile value must be between 1 and 9")
	value = p_value


func copy() -> Tile:
	return Tile.new(value)


func _to_string() -> String:
	return str(value)
