extends GutTest

const ActionScript := preload("res://src/backend/action.gd")
const GameScript := preload("res://src/backend/game.gd")


func test_new_game_uses_every_tile_without_a_set_aside_wall() -> void:
	var state: GameScript.State = GameScript.new_game(12345)
	var counts := PackedInt32Array()
	counts.resize(9)
	for tile: Tile in state.concealed_hand.tiles:
		counts[tile.value - 1] += 1
	counts[state.drawn_tile.value - 1] += 1
	for tile: Tile in state.draw_pile.tiles:
		counts[tile.value - 1] += 1

	assert_eq(state.concealed_hand.size(), 13)
	assert_eq(state.draw_pile.size(), 22)
	assert_eq(state.discards.size(), 0)
	assert_between(state.bonus_tile, 1, 9)
	assert_eq(counts, PackedInt32Array([4, 4, 4, 4, 4, 4, 4, 4, 4]))


func test_new_game_is_deterministic_for_a_seed() -> void:
	var first: GameScript.State = GameScript.new_game(2468)
	var second: GameScript.State = GameScript.new_game(2468)

	assert_eq(first.bonus_tile, second.bonus_tile)
	assert_eq(first.concealed_hand.values(), second.concealed_hand.values())
	assert_eq(first.drawn_tile.value, second.drawn_tile.value)
	assert_eq(first.draw_pile.values(), second.draw_pile.values())


func test_discarding_drawn_tile_draws_without_changing_concealed_hand() -> void:
	var state := _state("1234567891234", 5, "89", 1)
	var original_hand := state.concealed_hand.values()

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(13),
	)

	assert_eq(result.state.concealed_hand.values(), original_hand)
	assert_eq(result.state.drawn_tile.value, 9)
	assert_eq(result.state.draw_pile.values(), PackedInt32Array([8]))
	assert_eq(result.state.discards.values(), PackedInt32Array([5]))
	assert_eq(result.events.size(), 2)
	assert_true(result.events[0] is GameScript.TileDiscarded)
	assert_true(result.events[1] is GameScript.TileDrawn)
	assert_eq(state.drawn_tile.value, 5, "The input state remains unchanged")
	assert_eq(state.draw_pile.values(), PackedInt32Array([8, 9]))
	assert_true(state.discards.is_empty())


func test_discarding_concealed_tile_folds_drawn_tile_into_hand() -> void:
	var state := _state("1234567891234", 7, "89", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(0),
	)

	assert_eq(result.state.concealed_hand.size(), 13)
	assert_eq(result.state.concealed_hand.tiles[-1].value, 7)
	assert_eq(result.state.drawn_tile.value, 9)
	assert_eq(result.state.discards.values(), PackedInt32Array([1]))
	assert_eq(state.concealed_hand.tiles[0].value, 1, "The input hand remains unchanged")


func test_discard_is_rejected_when_no_tile_can_be_drawn() -> void:
	var state := _state("1234567891234", 5, "", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(13),
	)

	assert_not_same(result.state, state)
	assert_eq(result.state.draw_pile.values(), state.draw_pile.values())
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is GameScript.ActionRejected)


func test_discard_is_rejected_for_an_index_outside_the_hand() -> void:
	var state := _state("1234567891234", 5, "89", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(14),
	)

	assert_not_same(result.state, state)
	assert_eq(result.state.concealed_hand.values(), state.concealed_hand.values())
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is GameScript.ActionRejected)


func test_discard_is_rejected_for_a_negative_index() -> void:
	var state := _state("1234567891234", 5, "89", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(-1),
	)

	assert_eq(result.state.concealed_hand.values(), state.concealed_hand.values())
	assert_eq(result.state.draw_pile.values(), state.draw_pile.values())
	assert_true(result.events[0] is GameScript.ActionRejected)


func test_unknown_action_is_rejected() -> void:
	var state := _state("1234567891234", 5, "89", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.PlayerAction.new(),
	)

	assert_eq(result.state.phase, GameScript.Phase.PLAYING)
	assert_true(result.events[0] is GameScript.ActionRejected)


func test_final_draw_can_still_be_declared_as_tsumo() -> void:
	var state := _state("1112344567899", 1, "9", 1)
	var draw_result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(13),
	)

	assert_true(draw_result.state.draw_pile.is_empty())
	assert_eq(draw_result.state.drawn_tile.value, 9)
	assert_eq(draw_result.state.phase, GameScript.Phase.PLAYING)

	var tsumo_result: GameScript.UpdateResult = GameScript.update(
		draw_result.state,
		ActionScript.DeclareTsumo.new(),
	)
	assert_eq(tsumo_result.state.phase, GameScript.Phase.WON)


func test_non_winning_final_draw_exhausts_the_game() -> void:
	var state := _state("1122334455667", 1, "8", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(13),
	)

	assert_eq(result.state.phase, GameScript.Phase.EXHAUSTED)
	assert_true(result.state.draw_pile.is_empty())
	assert_true(result.events[-1] is GameScript.WallExhausted)


func test_returned_state_does_not_share_mutable_tiles_with_input() -> void:
	var state := _state("1234567891234", 5, "89", 1)
	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.Discard.new(13),
	)

	result.state.concealed_hand.tiles[0].value = 9
	assert_eq(state.concealed_hand.tiles[0].value, 1)


func test_all_tiles_are_conserved_through_every_draw() -> void:
	var state: GameScript.State = GameScript.new_game(9876)

	for _draw: int in range(22):
		var result: GameScript.UpdateResult = GameScript.update(
			state,
			ActionScript.Discard.new(13),
		)
		state = result.state

	assert_true(state.draw_pile.is_empty())
	assert_eq(state.discards.size(), 22)
	assert_eq(_tile_inventory(state), PackedInt32Array([4, 4, 4, 4, 4, 4, 4, 4, 4]))


func test_valid_tsumo_scores_exact_bonus_rank_as_exponential_han() -> void:
	var state := _state("1112344567899", 9, "123", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.DeclareTsumo.new(),
	)

	assert_eq(result.state.phase, GameScript.Phase.WON)
	assert_eq(result.state.han, 3)
	assert_eq(result.state.score, 8)
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is GameScript.TsumoDeclared)
	var event := result.events[0] as GameScript.TsumoDeclared
	assert_eq(event.han, 3)
	assert_eq(event.score, 8)
	assert_false(event.decompositions.is_empty())
	assert_eq(state.phase, GameScript.Phase.PLAYING, "The input state remains unchanged")
	assert_eq(state.han, 0)
	assert_eq(state.score, 0)


func test_tsumo_score_handles_zero_and_four_bonus_tiles() -> void:
	var zero_bonus := _state("1112223334445", 5, "123", 9)
	var four_bonus := _state("1111234567899", 9, "123", 1)

	var zero_result: GameScript.UpdateResult = GameScript.update(
		zero_bonus,
		ActionScript.DeclareTsumo.new(),
	)
	var four_result: GameScript.UpdateResult = GameScript.update(
		four_bonus,
		ActionScript.DeclareTsumo.new(),
	)

	assert_eq(zero_result.state.han, 0)
	assert_eq(zero_result.state.score, 1)
	assert_eq(four_result.state.han, 4)
	assert_eq(four_result.state.score, 16)


func test_seven_pairs_can_be_declared_as_tsumo() -> void:
	var state := _state("1122445577889", 9, "123", 3)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.DeclareTsumo.new(),
	)

	assert_eq(result.state.phase, GameScript.Phase.WON)
	var event := result.events[0] as GameScript.TsumoDeclared
	assert_eq(event.decompositions.size(), 1)
	assert_true(event.decompositions[0] is Hand.SevenPairsDecomposition)


func test_actions_after_tsumo_are_rejected_without_losing_win_result() -> void:
	var state := _state("1112344567899", 9, "123", 1)
	var won: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.DeclareTsumo.new(),
	)

	var rejected: GameScript.UpdateResult = GameScript.update(
		won.state,
		ActionScript.Discard.new(13),
	)

	assert_eq(rejected.state.phase, GameScript.Phase.WON)
	assert_eq(rejected.state.han, won.state.han)
	assert_eq(rejected.state.score, won.state.score)
	assert_true(rejected.events[0] is GameScript.ActionRejected)


func test_invalid_tsumo_is_rejected_without_changing_state() -> void:
	var state := _state("1122334455667", 8, "123", 1)

	var result: GameScript.UpdateResult = GameScript.update(
		state,
		ActionScript.DeclareTsumo.new(),
	)

	assert_not_same(result.state, state)
	assert_eq(result.state.concealed_hand.values(), state.concealed_hand.values())
	assert_eq(result.events.size(), 1)
	assert_true(result.events[0] is GameScript.ActionRejected)


func _state(
	concealed: String,
	drawn: int,
	pile: String,
	bonus: int,
) -> GameScript.State:
	return GameScript.State.new(
		GameScript.Phase.PLAYING,
		_deck(concealed),
		Tile.new(drawn),
		_deck(pile),
		Deck.new(),
		bonus,
	)


func _deck(values: String) -> Deck:
	var tiles: Array[Tile] = []
	for character: String in values:
		tiles.append(Tile.new(character.to_int()))
	return Deck.new(tiles)


func _tile_inventory(state: GameScript.State) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(9)
	var decks: Array[Deck] = [state.concealed_hand, state.draw_pile, state.discards]
	for deck: Deck in decks:
		for tile: Tile in deck.tiles:
			counts[tile.value - 1] += 1
	counts[state.drawn_tile.value - 1] += 1
	return counts
