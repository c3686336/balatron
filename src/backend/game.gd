class_name Game
extends RefCounted

const ActionScript := preload("res://src/backend/action.gd")
const HandScript := preload("res://src/backend/hand.gd")

enum Phase {
	PLAYING,
	WON,
	EXHAUSTED,
}


class State extends RefCounted:
	var phase: Phase
	var concealed_hand: Deck
	var drawn_tile: Tile
	var draw_pile: Deck
	var discards: Deck
	var bonus_tile: int
	var han: int
	var score: int

	func _init(
		p_phase: Phase,
		p_concealed_hand: Deck,
		p_drawn_tile: Tile,
		p_draw_pile: Deck,
		p_discards: Deck,
		p_bonus_tile: int,
		p_han: int = 0,
		p_score: int = 0,
	) -> void:
		assert(p_bonus_tile >= 1 and p_bonus_tile <= 9, "Bonus tile must be between 1 and 9")
		phase = p_phase
		concealed_hand = p_concealed_hand
		drawn_tile = p_drawn_tile
		draw_pile = p_draw_pile
		discards = p_discards
		bonus_tile = p_bonus_tile
		han = p_han
		score = p_score

	func copy() -> State:
		return State.new(
			phase,
			concealed_hand.copy(),
			drawn_tile.copy(),
			draw_pile.copy(),
			discards.copy(),
			bonus_tile,
			han,
			score,
		)


class Event extends RefCounted:
	pass


class TileDiscarded extends Event:
	var tile: Tile
	var index: int

	func _init(p_tile: Tile, p_index: int) -> void:
		tile = p_tile
		index = p_index


class TileDrawn extends Event:
	var tile: Tile

	func _init(p_tile: Tile) -> void:
		tile = p_tile


class TsumoDeclared extends Event:
	var decompositions: Array[HandScript.Decomposition]
	var han: int
	var score: int

	func _init(
		p_decompositions: Array[HandScript.Decomposition],
		p_han: int,
		p_score: int,
	) -> void:
		decompositions = p_decompositions
		han = p_han
		score = p_score


class Rejection extends RefCounted:
	pass


class GameEndedRejection extends Rejection:
	var phase: Phase

	func _init(p_phase: Phase) -> void:
		phase = p_phase


class UnknownActionRejection extends Rejection:
	pass


class EmptyDrawPileRejection extends Rejection:
	pass


class InvalidDiscardIndexRejection extends Rejection:
	var index: int
	var minimum: int
	var maximum: int

	func _init(p_index: int, p_minimum: int, p_maximum: int) -> void:
		index = p_index
		minimum = p_minimum
		maximum = p_maximum


class IncompleteHandRejection extends Rejection:
	pass


class ActionRejected extends Event:
	var reason: Rejection

	func _init(p_reason: Rejection) -> void:
		reason = p_reason


class WallExhausted extends Event:
	pass


class UpdateResult extends RefCounted:
	var state: State
	var events: Array[Event]

	func _init(p_state: State, p_events: Array[Event]) -> void:
		state = p_state
		events = p_events


static func new_game(seed_value: int) -> State:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bonus_tile := rng.randi_range(1, 9)
	var wall := Deck.full_deck()
	Util.shuffle_with_rng(wall.tiles, rng)

	var concealed_tiles: Array[Tile] = []
	concealed_tiles.append_array(wall.tiles.slice(0, 13))
	var drawn_tile: Tile = wall.tiles[13]
	var draw_tiles: Array[Tile] = []
	draw_tiles.append_array(wall.tiles.slice(14))

	return State.new(
		Phase.PLAYING,
		Deck.new(concealed_tiles),
		drawn_tile,
		Deck.new(draw_tiles),
		Deck.new(),
		bonus_tile,
	)


## Applies an action without mutating state. Callers should treat State and its
## nested value objects as immutable after passing them to this function.
static func update(state: State, action: ActionScript.PlayerAction) -> UpdateResult:
	if state.phase != Phase.PLAYING:
		return _rejected(state, GameEndedRejection.new(state.phase))

	if action is ActionScript.Discard:
		return _discard(state, action as ActionScript.Discard)
	if action is ActionScript.DeclareTsumo:
		return _declare_tsumo(state)
	return _rejected(state, UnknownActionRejection.new())


static func _discard(state: State, action: ActionScript.Discard) -> UpdateResult:
	if state.draw_pile.is_empty():
		return _rejected(state, EmptyDrawPileRejection.new())

	var drawn_index := state.concealed_hand.size()
	if action.index < 0 or action.index > drawn_index:
		return _rejected(state, InvalidDiscardIndexRejection.new(action.index, 0, drawn_index))

	var next_state := state.copy()
	var discarded: Tile
	if action.index == drawn_index:
		discarded = next_state.drawn_tile
	else:
		discarded = next_state.concealed_hand.tiles.pop_at(action.index)
		next_state.concealed_hand.tiles.append(next_state.drawn_tile)

	next_state.drawn_tile = next_state.draw_pile.tiles.pop_back()
	next_state.discards.tiles.append(discarded)

	var events: Array[Event] = [
		TileDiscarded.new(discarded, action.index),
		TileDrawn.new(next_state.drawn_tile),
	]
	if next_state.draw_pile.is_empty() and HandScript.decompose(_winning_tile_counts(next_state)).is_empty():
		next_state.phase = Phase.EXHAUSTED
		events.append(WallExhausted.new())
	return UpdateResult.new(next_state, events)


static func _declare_tsumo(state: State) -> UpdateResult:
	var tile_counts := _winning_tile_counts(state)
	var decompositions := HandScript.decompose(tile_counts)
	if decompositions.is_empty():
		return _rejected(state, IncompleteHandRejection.new())

	var next_state := state.copy()
	next_state.phase = Phase.WON
	next_state.han = tile_counts[state.bonus_tile - 1]
	next_state.score = 1 << next_state.han

	var events: Array[Event] = [
		TsumoDeclared.new(decompositions, next_state.han, next_state.score),
	]
	return UpdateResult.new(next_state, events)


static func _winning_tile_counts(state: State) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(9)
	for tile: Tile in state.concealed_hand.tiles:
		counts[tile.value - 1] += 1
	counts[state.drawn_tile.value - 1] += 1
	return counts


static func _rejected(state: State, reason: Rejection) -> UpdateResult:
	var events: Array[Event] = [ActionRejected.new(reason)]
	return UpdateResult.new(state.copy(), events)
