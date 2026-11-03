class_name Deck
extends RefCounted

var tiles: Array[Tile]


func _init(p_tiles: Array[Tile] = []) -> void:
	tiles = []
	tiles.append_array(p_tiles)


func copy() -> Deck:
	var copied_tiles: Array[Tile] = []
	for tile: Tile in tiles:
		copied_tiles.append(tile.copy())
	return Deck.new(copied_tiles)


func values() -> PackedInt32Array:
	var result := PackedInt32Array()
	for tile: Tile in tiles:
		result.append(tile.value)
	return result


func is_empty() -> bool:
	return tiles.is_empty()


func size() -> int:
	return tiles.size()


static func full_deck() -> Deck:
	var result := Deck.new()
	for value: int in range(1, 10):
		for _copy: int in range(4):
			result.tiles.append(Tile.new(value))
	return result
