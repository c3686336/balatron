@abstract
class_name Item
extends RefCounted

var _id: String
var _display_name: String
var _description: String

var id: String:
	get:
		return _id

var display_name: String:
	get:
		return _display_name

var description: String:
	get:
		return _description


func _init(p_id: String, p_display_name: String, p_description: String) -> void:
	_id = p_id
	_display_name = p_display_name
	_description = p_description
