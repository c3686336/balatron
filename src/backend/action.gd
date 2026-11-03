class_name Action
extends RefCounted

class PlayerAction extends RefCounted:
	pass


class Discard extends PlayerAction:
	var index: int

	func _init(p_index: int) -> void:
		index = p_index


class DeclareTsumo extends PlayerAction:
	pass
