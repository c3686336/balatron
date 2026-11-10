@abstract
class_name YakuItem
extends "res://src/backend/items/item.gd"

const HandScript := preload("res://src/backend/hand.gd")

var _han: int

var han: int:
	get:
		return _han


func _init(p_id: String, p_display_name: String, p_description: String, p_han: int) -> void:
	super(p_id, p_display_name, p_description)
	_han = p_han


@abstract
func matches(tile_counts: PackedInt32Array, decomposition: HandScript.Decomposition) -> bool
