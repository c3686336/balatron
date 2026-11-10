class_name Scoring
extends RefCounted

const HandScript := preload("res://src/backend/hand.gd")


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

	func _init(
		p_selected_decomposition: HandScript.Decomposition,
		p_bonus_rank_contribution: BonusRankContribution,
		p_points: int,
	) -> void:
		selected_decomposition = p_selected_decomposition
		bonus_rank_contribution = p_bonus_rank_contribution
		han = bonus_rank_contribution.han
		points = p_points


## Scores eligible decompositions of the supplied nine rank counts without
## modifying any input. Eligibility is the caller's responsibility; an empty
## candidate list returns null. Treat the result and its decomposition as read-only.
static func evaluate(
	tile_counts: PackedInt32Array,
	bonus_rank: int,
	eligible_decompositions: Array[HandScript.Decomposition],
) -> Result:
	if eligible_decompositions.is_empty():
		return null

	var bonus_han := tile_counts[bonus_rank - 1]
	# Rank-only scoring is identical for every eligible interpretation.
	return Result.new(
		eligible_decompositions[0],
		BonusRankContribution.new(bonus_rank, bonus_han),
		1 << bonus_han,
	)
