extends "res://src/backend/items/yaku_item.gd"


func _init() -> void:
	super("chiitoitsu", "Chiitoitsu", "Seven distinct pairs (+2 han).", 2)


func matches(_tile_counts: PackedInt32Array, decomposition: HandScript.Decomposition) -> bool:
	return decomposition is HandScript.SevenPairsDecomposition
