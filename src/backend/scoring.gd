class_name Scoring
extends RefCounted

const HandScript := preload("res://src/backend/hand.gd")
const ItemCatalogScript := preload("res://src/backend/item_catalog.gd")


class BonusRankContribution extends RefCounted:
	var rank: int
	var han: int

	func _init(p_rank: int, p_han: int) -> void:
		rank = p_rank
		han = p_han


class Result extends RefCounted:
	var selected_decomposition: HandScript.Decomposition
	var han: int
	var points: int
	var bonus_rank_contribution: BonusRankContribution
	var item_contributions: Array[ItemCatalogScript.Contribution]

	func _init(
		p_selected_decomposition: HandScript.Decomposition,
		p_bonus_rank_contribution: BonusRankContribution,
		p_item_contributions: Array[ItemCatalogScript.Contribution],
	) -> void:
		selected_decomposition = p_selected_decomposition
		bonus_rank_contribution = p_bonus_rank_contribution
		item_contributions = p_item_contributions
		han = bonus_rank_contribution.han
		for contribution: ItemCatalogScript.Contribution in item_contributions:
			han += contribution.han
		points = 1 << han


## Scores eligible decompositions of the supplied nine rank counts without
## modifying any input. Eligibility is the caller's responsibility; an empty
## candidate list returns null. Treat the result and its decomposition as read-only.
static func evaluate(
	tile_counts: PackedInt32Array,
	bonus_rank: int,
	eligible_decompositions: Array[HandScript.Decomposition],
	equipped_items: Array[String] = [],
) -> Result:
	if eligible_decompositions.is_empty():
		return null

	var bonus := BonusRankContribution.new(bonus_rank, tile_counts[bonus_rank - 1])
	if equipped_items.is_empty():
		return Result.new(eligible_decompositions[0], bonus, [])

	var best: Result = null
	for decomposition: HandScript.Decomposition in eligible_decompositions:
		var contributions := ItemCatalogScript.contributions_for(
			tile_counts, decomposition, equipped_items,
		)
		var candidate := Result.new(decomposition, bonus, contributions)
		if best == null or candidate.han > best.han:
			best = candidate
	return best
