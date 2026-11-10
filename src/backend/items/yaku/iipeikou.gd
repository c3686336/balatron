extends "res://src/backend/items/yaku_item.gd"


func _init() -> void:
	super("iipeikou", "Iipeikou", "At least one duplicated sequence in a normal interpretation (+1 han).", 1)


func matches(_tile_counts: PackedInt32Array, decomposition: HandScript.Decomposition) -> bool:
	if not decomposition is HandScript.NormalDecomposition:
		return false
	var normal := decomposition as HandScript.NormalDecomposition
	for index: int in range(normal.sequences.size()):
		for other: int in range(index + 1, normal.sequences.size()):
			if normal.sequences[index].first_tile == normal.sequences[other].first_tile:
				return true
	return false
