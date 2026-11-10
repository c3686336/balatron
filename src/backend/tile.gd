class_name Tile
extends RefCounted

var value: int


func _init(p_value: int) -> void:
	assert(p_value >= 1 and p_value <= 9, "Tile value must be between 1 and 9")
	value = p_value


## Converts a valid tile value (1 through 9) to its zero-based count index.
static func value_to_index(tile_value: int) -> int:
	return tile_value - 1


func copy() -> Tile:
	return Tile.new(value)


func _to_string() -> String:
	return str(value)
