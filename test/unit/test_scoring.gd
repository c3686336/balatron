extends GutTest

const HandScript := preload("res://src/backend/hand.gd")
const ScoringScript := preload("res://src/backend/scoring.gd")


func test_scoring_requires_an_eligible_decomposition() -> void:
	var counts := PackedInt32Array([2, 2, 0, 2, 2, 0, 2, 2, 2])
	var eligible: Array[HandScript.Decomposition] = []

	assert_null(ScoringScript.evaluate(counts, 1, eligible))


func test_repeated_previews_leave_inputs_and_earlier_results_unchanged() -> void:
	var counts := PackedInt32Array([2, 2, 0, 2, 2, 0, 2, 2, 2])
	var original_counts := counts.duplicate()
	var eligible := HandScript.decompose(counts)
	var pairs := (eligible[0] as HandScript.SevenPairsDecomposition).pairs

	var first := ScoringScript.evaluate(counts, 1, eligible)
	var second := ScoringScript.evaluate(counts, 3, eligible)
	var repeated := ScoringScript.evaluate(counts, 1, eligible)

	assert_eq(first.han, 2)
	assert_eq(first.points, 4)
	assert_eq(first.bonus_rank_contribution.rank, 1)
	assert_eq(first.bonus_rank_contribution.han, 2)
	assert_eq(second.han, 0)
	assert_eq(second.points, 1)
	assert_eq(second.bonus_rank_contribution.rank, 3)
	assert_eq(second.bonus_rank_contribution.han, 0)
	assert_eq(repeated.han, first.han)
	assert_eq(repeated.points, first.points)
	assert_eq(counts, original_counts)
	assert_eq(eligible.size(), 1)
	var pair_tiles: Array[int] = []
	for pair: HandScript.Pair in pairs:
		pair_tiles.append(pair.tile)
	pair_tiles.sort()
	assert_eq(pair_tiles, [1, 2, 4, 5, 7, 8, 9])
