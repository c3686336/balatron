extends "res://src/backend/items/yaku_item.gd"


func _init() -> void:
	super("sanankou", "Sanankou", "At least three concealed triplets (+2 han).", 2)


func matches(_tile_counts: PackedInt32Array, decomposition: HandScript.Decomposition) -> bool:
	if not decomposition is HandScript.NormalDecomposition:
		return false
	return (decomposition as HandScript.NormalDecomposition).triplets.size() >= 3
