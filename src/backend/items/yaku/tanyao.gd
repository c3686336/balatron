extends "res://src/backend/items/yaku_item.gd"


func _init() -> void:
	super("tanyao", "Tanyao", "No rank 1 or 9 tiles (+1 han).", 1)


func matches(tile_counts: PackedInt32Array, _decomposition: HandScript.Decomposition) -> bool:
	return tile_counts[0] == 0 and tile_counts[8] == 0
