extends GutTest

const HandScript := preload("res://src/backend/hand.gd")


func test_decomposes_standard_winning_hand() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11123445678999")

	assert_eq(result.size(), 1)
	if result.size() != 1:
		return

	var normal := result[0] as HandScript.NormalDecomposition
	assert_not_null(normal)
	if normal == null:
		return

	assert_eq(normal.pair.tile, 9)
	assert_eq(_sequence_starts(normal), [2, 4, 7])
	assert_eq(_triplet_tiles(normal), [1])
	assert_eq(_quad_tiles(normal), [])


func test_can_use_one_tile_value_in_a_sequence_and_a_triplet() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11112345678999")

	assert_eq(result.size(), 1)
	if result.size() != 1:
		return

	var normal := result[0] as HandScript.NormalDecomposition
	assert_not_null(normal)
	if normal == null:
		return

	assert_eq(normal.pair.tile, 9)
	assert_eq(_sequence_starts(normal), [1, 4, 7])
	assert_eq(_triplet_tiles(normal), [1])


func test_finds_triplet_when_highest_tile_is_used_four_times() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11123456789999")

	assert_eq(result.size(), 1)
	if result.size() != 1:
		return

	var normal := result[0] as HandScript.NormalDecomposition
	assert_not_null(normal)
	if normal == null:
		return

	assert_eq(normal.pair.tile, 1)
	assert_eq(_sequence_starts(normal), [1, 4, 7])
	assert_eq(_triplet_tiles(normal), [9])


func test_returns_no_decomposition_for_oversized_unparseable_hand() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11123333445678999")

	assert_true(result.is_empty())


func test_returns_no_decomposition_for_empty_hand() -> void:
	var result: Array[HandScript.Decomposition] = HandScript.decompose(_empty_counts())

	assert_true(result.is_empty())


func test_returns_every_decomposition_of_ambiguous_hand() -> void:
	# This shape supports three different pair-5 bodies and one pair-2 body.
	var result: Array[HandScript.Decomposition] = _decompose("11122233344455")
	var normals: Array[HandScript.NormalDecomposition] = _normal_decompositions(result)

	assert_eq(normals.size(), 4)
	assert_eq(_pair_tiles(normals), [2, 5, 5, 5])
	assert_has(_normal_signatures(normals), "2|2,3,3|1|")
	assert_has(_normal_signatures(normals), "5|1,1,1|4|")
	assert_has(_normal_signatures(normals), "5|2,2,2|1|")
	assert_has(_normal_signatures(normals), "5||1,2,3,4|")


func test_declared_quad_counts_as_one_of_four_melds() -> void:
	var result: Array[HandScript.Decomposition] = _decompose(
		"11123445677",
		PackedInt32Array([9]),
	)

	assert_eq(result.size(), 1)
	if result.size() != 1:
		return

	var normal := result[0] as HandScript.NormalDecomposition
	assert_not_null(normal)
	if normal == null:
		return

	assert_eq(normal.pair.tile, 7)
	assert_eq(_sequence_starts(normal), [2, 4])
	assert_eq(_triplet_tiles(normal), [1])
	assert_eq(_quad_tiles(normal), [9])


func test_seven_consecutive_pairs_include_all_normal_interpretations() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11223344556677")
	var normals: Array[HandScript.NormalDecomposition] = _normal_decompositions(result)
	var seven_pairs: Array[HandScript.SevenPairsDecomposition] = _seven_pairs_decompositions(result)

	assert_eq(result.size(), 4)
	assert_eq(_pair_tiles(normals), [1, 4, 7])
	assert_eq(seven_pairs.size(), 1)
	if seven_pairs.size() == 1:
		assert_eq(_seven_pair_tiles(seven_pairs[0]), [1, 2, 3, 4, 5, 6, 7])


func test_returns_both_parses_of_three_two_two_two_two_three_shape() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11122334455666")
	var normals: Array[HandScript.NormalDecomposition] = _normal_decompositions(result)

	assert_eq(result.size(), 2)
	assert_eq(_pair_tiles(normals), [2, 5])


func test_preserves_distinct_meld_choices_with_the_same_pair() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11122223333444")
	var normals: Array[HandScript.NormalDecomposition] = _normal_decompositions(result)

	assert_eq(result.size(), 4)
	assert_eq(_pair_tiles(normals), [1, 1, 4, 4])


func test_decomposes_non_normal_seven_pairs_hand() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("11224455778899")

	assert_eq(result.size(), 1)
	if result.size() != 1:
		return

	var seven_pairs := result[0] as HandScript.SevenPairsDecomposition
	assert_not_null(seven_pairs)
	if seven_pairs != null:
		assert_eq(_seven_pair_tiles(seven_pairs), [1, 2, 4, 5, 7, 8, 9])


func test_four_identical_tiles_do_not_count_as_two_pairs() -> void:
	var result: Array[HandScript.Decomposition] = _decompose("112233444455")

	assert_true(_seven_pairs_decompositions(result).is_empty())


func test_declared_quad_hand_cannot_be_seven_pairs() -> void:
	var result: Array[HandScript.Decomposition] = _decompose(
		"1122334455",
		PackedInt32Array([9]),
	)

	assert_true(_seven_pairs_decompositions(result).is_empty())


func _decompose(
	tiles: String,
	declared_quads: PackedInt32Array = PackedInt32Array(),
) -> Array[HandScript.Decomposition]:
	return HandScript.decompose(_counts(tiles), declared_quads)


func _counts(tiles: String) -> PackedInt32Array:
	var counts := _empty_counts()
	for character: String in tiles:
		var tile := character.to_int()
		counts[tile - 1] += 1
	return counts


func _empty_counts() -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(9)
	return counts


func _normal_decompositions(
	decompositions: Array[HandScript.Decomposition],
) -> Array[HandScript.NormalDecomposition]:
	var normals: Array[HandScript.NormalDecomposition] = []
	for decomposition: HandScript.Decomposition in decompositions:
		if decomposition is HandScript.NormalDecomposition:
			normals.append(decomposition as HandScript.NormalDecomposition)
	return normals


func _seven_pairs_decompositions(
	decompositions: Array[HandScript.Decomposition],
) -> Array[HandScript.SevenPairsDecomposition]:
	var seven_pairs: Array[HandScript.SevenPairsDecomposition] = []
	for decomposition: HandScript.Decomposition in decompositions:
		if decomposition is HandScript.SevenPairsDecomposition:
			seven_pairs.append(decomposition as HandScript.SevenPairsDecomposition)
	return seven_pairs


func _sequence_starts(normal: HandScript.NormalDecomposition) -> Array[int]:
	var starts: Array[int] = []
	for sequence: HandScript.Sequence in normal.sequences:
		starts.append(sequence.first_tile)
	starts.sort()
	return starts


func _triplet_tiles(normal: HandScript.NormalDecomposition) -> Array[int]:
	var tiles: Array[int] = []
	for triplet: HandScript.Triplet in normal.triplets:
		tiles.append(triplet.tile)
	tiles.sort()
	return tiles


func _quad_tiles(normal: HandScript.NormalDecomposition) -> Array[int]:
	var tiles: Array[int] = []
	for quad: HandScript.Quad in normal.quads:
		tiles.append(quad.tile)
	tiles.sort()
	return tiles


func _pair_tiles(normals: Array[HandScript.NormalDecomposition]) -> Array[int]:
	var tiles: Array[int] = []
	for normal: HandScript.NormalDecomposition in normals:
		tiles.append(normal.pair.tile)
	tiles.sort()
	return tiles


func _seven_pair_tiles(seven_pairs: HandScript.SevenPairsDecomposition) -> Array[int]:
	var tiles: Array[int] = []
	for pair: HandScript.Pair in seven_pairs.pairs:
		tiles.append(pair.tile)
	tiles.sort()
	return tiles


func _normal_signatures(normals: Array[HandScript.NormalDecomposition]) -> Array[String]:
	var signatures: Array[String] = []
	for normal: HandScript.NormalDecomposition in normals:
		signatures.append(
			"%d|%s|%s|%s" % [
				normal.pair.tile,
				_join_ints(_sequence_starts(normal)),
				_join_ints(_triplet_tiles(normal)),
				_join_ints(_quad_tiles(normal)),
			]
		)
	return signatures


func _join_ints(values: Array[int]) -> String:
	var strings: PackedStringArray = []
	for value: int in values:
		strings.append(str(value))
	return ",".join(strings)
