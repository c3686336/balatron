class_name ItemCatalog
extends RefCounted

const HandScript := preload("res://src/backend/hand.gd")
const ItemScript := preload("res://src/backend/items/item.gd")
const YakuItemScript := preload("res://src/backend/items/yaku_item.gd")

# Shared definitions contain metadata and matching behavior, not owned runtime state.
static var _definitions: Dictionary[String, ItemScript] = _build_definitions()


class Contribution extends RefCounted:
	var item_id: String
	var han: int

	func _init(p_item_id: String, p_han: int) -> void:
		item_id = p_item_id
		han = p_han


static func _build_definitions() -> Dictionary[String, ItemScript]:
	var items: Array[ItemScript] = [
		preload("res://src/backend/items/yaku/tanyao.gd").new(),
		preload("res://src/backend/items/yaku/iipeikou.gd").new(),
		preload("res://src/backend/items/yaku/chiitoitsu.gd").new(),
		preload("res://src/backend/items/yaku/suuanko.gd").new(),
		preload("res://src/backend/items/yaku/sanankou.gd").new(),
	]
	var definitions: Dictionary[String, ItemScript] = {}
	for item: ItemScript in items:
		definitions[item.id] = item
	return definitions


static func ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_definitions.keys())
	return result


static func name_for(item_id: String) -> String:
	return _definitions[item_id].display_name


static func description_for(item_id: String) -> String:
	return _definitions[item_id].description


static func loadout_error(equipped_items: Array[String]) -> String:
	var seen: Dictionary[String, bool] = {}
	for item_id: String in equipped_items:
		if not _definitions.has(item_id):
			return "Unknown item ID: %s" % item_id
		if seen.has(item_id):
			return "Duplicate item ID: %s" % item_id
		seen[item_id] = true
	return ""


## Matches each equipped passive once for one complete-hand interpretation.
## Candidate selection and score arithmetic belong to Scoring.
static func contributions_for(
	tile_counts: PackedInt32Array,
	decomposition: HandScript.Decomposition,
	equipped_items: Array[String],
) -> Array[Contribution]:
	var contributions: Array[Contribution] = []
	# Visit definitions, not inventory entries: duplicate IDs cannot stack.
	for item_id: String in _definitions:
		if item_id not in equipped_items:
			continue
		var definition := _definitions[item_id]
		if definition is YakuItemScript:
			var yaku := definition as YakuItemScript
			if yaku.matches(tile_counts, decomposition):
				contributions.append(Contribution.new(yaku.id, yaku.han))
	return contributions
