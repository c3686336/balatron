class_name ItemCatalog
extends RefCounted

const HandScript := preload("res://src/backend/hand.gd")

# Stable IDs and read-only metadata; no per-owned-item runtime state.
const DEFINITIONS := {
	"tanyao": ["Tanyao", "No rank 1 or 9 tiles (+1 han).", 1],
	"iipeikou": ["Iipeikou", "At least one duplicated sequence in a normal interpretation (+1 han).", 1],
	"chiitoitsu": ["Chiitoitsu", "Seven distinct pairs (+2 han).", 2],
	"toitoi": ["Toitoi", "Four concealed triplets (+2 han).", 2],
	"sanankou": ["Sanankou", "At least three concealed triplets (+2 han).", 2],
}


class Contribution extends RefCounted:
	var item_id: String
	var han: int

	func _init(p_item_id: String, p_han: int) -> void:
		item_id = p_item_id
		han = p_han




static func ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(DEFINITIONS.keys())
	return result


static func name_for(item_id: String) -> String:
	return DEFINITIONS[item_id][0]


static func description_for(item_id: String) -> String:
	return DEFINITIONS[item_id][1]


static func loadout_error(equipped_items: Array[String]) -> String:
	var seen: Dictionary[String, bool] = {}
	for item_id: String in equipped_items:
		if not DEFINITIONS.has(item_id):
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
	# Visit catalog IDs, not inventory entries: duplicate IDs cannot stack.
	for item_id: String in DEFINITIONS:
		if item_id in equipped_items and _matches(item_id, tile_counts, decomposition):
			contributions.append(Contribution.new(item_id, DEFINITIONS[item_id][2]))
	return contributions


static func _matches(
	item_id: String,
	tile_counts: PackedInt32Array,
	decomposition: HandScript.Decomposition,
) -> bool:
	if item_id == "tanyao":
		return tile_counts[0] == 0 and tile_counts[8] == 0
	if item_id == "chiitoitsu":
		return decomposition is HandScript.SevenPairsDecomposition
	if not decomposition is HandScript.NormalDecomposition:
		return false
	var normal := decomposition as HandScript.NormalDecomposition
	match item_id:
		"iipeikou":
			for index: int in range(normal.sequences.size()):
				for other: int in range(index + 1, normal.sequences.size()):
					if normal.sequences[index].first_tile == normal.sequences[other].first_tile:
						return true
		"toitoi":
			return normal.triplets.size() == 4
		"sanankou":
			return normal.triplets.size() >= 3
	return false
