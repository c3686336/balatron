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


## Returns every distinct decomposition of a complete concealed hand.
## tile_counts has nine entries for tiles 1 through 9. Each declared quad
## replaces one of the four melds and reduces the concealed hand size by three.
static func decompose(
	_tile_counts: PackedInt32Array,
	_declared_quads: PackedInt32Array = PackedInt32Array(),
) -> Array[Decomposition]:
	return []
