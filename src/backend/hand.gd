class_name Hand
extends RefCounted


class Decomposition extends RefCounted:
	pass


class Pair extends RefCounted:
	var tile: int

	func _init(p_tile: int) -> void:
		tile = p_tile


class Sequence extends RefCounted:
	var first_tile: int

	func _init(p_first_tile: int) -> void:
		first_tile = p_first_tile


class Triplet extends RefCounted:
	var tile: int

	func _init(p_tile: int) -> void:
		tile = p_tile


class Quad extends RefCounted:
	var tile: int

	func _init(p_tile: int) -> void:
		tile = p_tile


class NormalDecomposition extends Decomposition:
	var pair: Pair
	var sequences: Array[Sequence]
	var triplets: Array[Triplet]
	var quads: Array[Quad]

	func _init(
		p_pair: Pair,
		p_sequences: Array[Sequence],
		p_triplets: Array[Triplet],
		p_quads: Array[Quad],
	) -> void:
		pair = p_pair
		sequences = p_sequences
		triplets = p_triplets
		quads = p_quads


class SevenPairsDecomposition extends Decomposition:
	var pairs: Array[Pair]

	func _init(p_pairs: Array[Pair]) -> void:
		pairs = p_pairs


class PairBody extends RefCounted:
	var pair: Pair
	var body: PackedInt32Array

	func _init(p_pair: Pair, p_body: PackedInt32Array) -> void:
		pair = p_pair
		body = p_body


## Parses a hand for Seven Pairs. Returns null if it's not interpretable that way.
static func parse_seven_pairs(
	tile_counts: PackedInt32Array,
	declared_quads: PackedInt32Array = PackedInt32Array(),
) -> Decomposition:
	if not declared_quads.is_empty():
		return null

	var pairs: Array[Pair] = []
	for index: int in range(tile_counts.size()):
		if tile_counts[index] == 2:
			pairs.append(Pair.new(index + 1))
		elif tile_counts[index] != 0:
			return null

	if pairs.size() == 7:
		return SevenPairsDecomposition.new(pairs)
	return null


static func parse_pairs(tile_counts: PackedInt32Array) -> Array[PairBody]:
	var bodies: Array[PairBody] = []

	for index: int in range(tile_counts.size()):
		if tile_counts[index] >= 2:
			var body := tile_counts.duplicate()
			body[index] -= 2
			bodies.append(PairBody.new(Pair.new(index + 1), body))

	return bodies


static func parse_body(
	pair_body: PairBody,
	quads: Array[Quad],
) -> Array[Decomposition]:
	var results: Array[Decomposition] = []
	var sequences: Array[Sequence] = []
	var triplets: Array[Triplet] = []
	_parse_body_recursive(
		pair_body.body,
		4 - quads.size(),
		pair_body.pair,
		sequences,
		triplets,
		quads,
		results,
	)
	return results


static func _parse_body_recursive(
	body: PackedInt32Array,
	melds_left: int,
	pair: Pair,
	sequences: Array[Sequence],
	triplets: Array[Triplet],
	quads: Array[Quad],
	results: Array[Decomposition],
) -> void:
	var first_tile_index := _first_remaining_tile(body)
	if first_tile_index == -1:
		if melds_left == 0:
			var result_sequences: Array[Sequence] = []
			var result_triplets: Array[Triplet] = []
			var result_quads: Array[Quad] = []
			result_sequences.append_array(sequences)
			result_triplets.append_array(triplets)
			result_quads.append_array(quads)
			results.append(
				NormalDecomposition.new(
					pair,
					result_sequences,
					result_triplets,
					result_quads,
				)
			)
		return

	if melds_left == 0:
		return

	if (
		first_tile_index <= 6
		and body[first_tile_index + 1] > 0
		and body[first_tile_index + 2] > 0
	):
		body[first_tile_index] -= 1
		body[first_tile_index + 1] -= 1
		body[first_tile_index + 2] -= 1
		sequences.append(Sequence.new(first_tile_index + 1))

		_parse_body_recursive(
			body,
			melds_left - 1,
			pair,
			sequences,
			triplets,
			quads,
			results,
		)

		sequences.pop_back()
		body[first_tile_index] += 1
		body[first_tile_index + 1] += 1
		body[first_tile_index + 2] += 1

	if body[first_tile_index] >= 3:
		body[first_tile_index] -= 3
		triplets.append(Triplet.new(first_tile_index + 1))

		_parse_body_recursive(
			body,
			melds_left - 1,
			pair,
			sequences,
			triplets,
			quads,
			results,
		)

		triplets.pop_back()
		body[first_tile_index] += 3


static func _first_remaining_tile(body: PackedInt32Array) -> int:
	for index: int in range(body.size()):
		if body[index] > 0:
			return index
	return -1


static func parse_normal_hand(
	tile_counts: PackedInt32Array,
	declared_quads: PackedInt32Array = PackedInt32Array(),
) -> Array[Decomposition]:
	var results: Array[Decomposition] = []
	var seen_decompositions: Dictionary[String, bool] = {}
	var quads: Array[Quad] = []
	for tile: int in declared_quads:
		quads.append(Quad.new(tile))

	for pair_body: PairBody in parse_pairs(tile_counts):
		for decomposition: Decomposition in parse_body(pair_body, quads):
			var normal := decomposition as NormalDecomposition
			var key := _normal_decomposition_key(normal)
			if not seen_decompositions.has(key):
				seen_decompositions[key] = true
				results.append(normal)

	return results


static func _normal_decomposition_key(normal: NormalDecomposition) -> String:
	var sequence_tiles: Array[int] = []
	var triplet_tiles: Array[int] = []
	var quad_tiles: Array[int] = []
	for sequence: Sequence in normal.sequences:
		sequence_tiles.append(sequence.first_tile)
	for triplet: Triplet in normal.triplets:
		triplet_tiles.append(triplet.tile)
	for quad: Quad in normal.quads:
		quad_tiles.append(quad.tile)
	sequence_tiles.sort()
	triplet_tiles.sort()
	quad_tiles.sort()
	return "%d|%s|%s|%s" % [
		normal.pair.tile,
		_int_array_key(sequence_tiles),
		_int_array_key(triplet_tiles),
		_int_array_key(quad_tiles),
	]


static func _int_array_key(values: Array[int]) -> String:
	var strings: PackedStringArray = []
	for value: int in values:
		strings.append(str(value))
	return ",".join(strings)


static func _is_valid_input(
	tile_counts: PackedInt32Array,
	declared_quads: PackedInt32Array,
) -> bool:
	if tile_counts.size() != 9 or declared_quads.size() > 4:
		return false

	var tile_total := 0
	for count: int in tile_counts:
		if count < 0 or count > 4:
			return false
		tile_total += count

	for tile: int in declared_quads:
		if tile < 1 or tile > 9:
			return false

	return tile_total == 14 - declared_quads.size() * 3

## Returns every distinct decomposition of a complete concealed hand.
## tile_counts has nine entries for tiles 1 through 9. Each declared quad
## replaces one of the four melds and reduces the concealed hand size by three.
static func decompose(
	tile_counts: PackedInt32Array,
	declared_quads: PackedInt32Array = PackedInt32Array(),
) -> Array[Decomposition]:
	var results: Array[Decomposition] = []
	if not _is_valid_input(tile_counts, declared_quads):
		return results

	var seven_pairs_result := parse_seven_pairs(tile_counts, declared_quads)
	if seven_pairs_result != null:
		results.append(seven_pairs_result)

	results.append_array(parse_normal_hand(tile_counts, declared_quads))
	return results
