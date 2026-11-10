extends SceneTree

const ActionScript := preload("res://src/backend/action.gd")
const GameScript := preload("res://src/backend/game.gd")
const ItemCatalogScript := preload("res://src/backend/item_catalog.gd")
const HandScript := preload("res://src/backend/hand.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() == 1 and arguments[0] == "--list-items":
		_print_catalog()
		quit()
		return
	var seed := int(Time.get_unix_time_from_system())
	var equipped_items: Array[String] = []
	if not arguments.is_empty():
		if not arguments[0].is_valid_int():
			print("Rejected: expected a seed followed by item IDs, or --list-items.")
			quit(1)
			return
		seed = arguments[0].to_int()
		for index: int in range(1, arguments.size()):
			equipped_items.append(arguments[index])
	var loadout_error := ItemCatalogScript.loadout_error(equipped_items)
	if not loadout_error.is_empty():
		print("Rejected: %s. Use --list-items for the catalog." % loadout_error)
		quit(1)
		return
	var state: GameScript.State = GameScript.new_game(seed, equipped_items)
	print("Balatron CLI (seed %d)" % seed)
	print("Equipped (locked for this hand): %s" % (
		", ".join(state.equipped_items) if not state.equipped_items.is_empty() else "none"
	))
	print("Commands: d INDEX, t, h, q")

	while state.phase == GameScript.Phase.PLAYING:
		_print_state(state)
		var input := OS.read_string_from_stdin().strip_edges().to_lower()
		if input.is_empty() or input == "q":
			break
		if input == "h":
			print("d INDEX discards that position and draws; t declares tsumo; q quits")
			continue

		var action: ActionScript.PlayerAction = _parse_action(input)
		if action == null:
			print("Invalid command. Use d INDEX, t, h, or q.")
			continue

		var result: GameScript.UpdateResult = GameScript.update(state, action)
		state = result.state
		_print_events(result.events)

	if state.phase == GameScript.Phase.WON:
		print("Tsumo: %d han, %d points" % [state.han, state.score])
	elif state.phase == GameScript.Phase.EXHAUSTED:
		print("The wall is empty. Game over.")
	quit()


func _print_catalog() -> void:
	for item_id: String in ItemCatalogScript.ids():
		print("%s | %s: %s" % [
			item_id,
			ItemCatalogScript.name_for(item_id),
			ItemCatalogScript.description_for(item_id),
		])


func _parse_action(input: String) -> ActionScript.PlayerAction:
	if input == "t":
		return ActionScript.DeclareTsumo.new()
	var parts := input.split(" ", false)
	if parts.size() == 2 and parts[0] == "d" and parts[1].is_valid_int():
		return ActionScript.Discard.new(parts[1].to_int())
	return null


func _print_state(state: GameScript.State) -> void:
	var hand_parts: PackedStringArray = []
	for index: int in range(state.concealed_hand.size()):
		hand_parts.append("%d:%s" % [index, _tile_text(state.concealed_hand.tiles[index], state)])
	var drawn_index := state.concealed_hand.size()
	hand_parts.append("%d:%s" % [drawn_index, _tile_text(state.drawn_tile, state)])
	print("Bonus rank: %d | Wall: %d | Discards: %s" % [
		state.bonus_tile,
		state.draw_pile.size(),
		state.discards.values(),
	])
	print("Hand: %s" % "  ".join(hand_parts))


func _tile_text(tile: Tile, state: GameScript.State) -> String:
	if tile.value == state.bonus_tile:
		return "%d*" % tile.value
	return str(tile.value)


func _print_events(events: Array[GameScript.Event]) -> void:
	for event: GameScript.Event in events:
		if event is GameScript.ActionRejected:
			print("Rejected: %s" % rejection_text((event as GameScript.ActionRejected).reason))
		elif event is GameScript.TileDiscarded:
			print("Discarded %d" % (event as GameScript.TileDiscarded).tile.value)
		elif event is GameScript.TileDrawn:
			print("Drew %d" % (event as GameScript.TileDrawn).tile.value)
		elif event is GameScript.TsumoDeclared:
			var scoring := (event as GameScript.TsumoDeclared).scoring
			print("Interpretation: %s" % _interpretation_text(scoring.selected_decomposition))
			var bonus := scoring.bonus_rank_contribution
			print("Bonus rank %d: %d matching tiles = %d han" % [
				bonus.rank,
				bonus.han,
				bonus.han,
			])
			for contribution: ItemCatalogScript.Contribution in scoring.item_contributions:
				print("%s (%s): +%d han" % [
					ItemCatalogScript.name_for(contribution.item_id),
					contribution.item_id,
					contribution.han,
				])
			print("Total: %d han; 2^%d = %d points" % [
				scoring.han,
				scoring.han,
				scoring.points,
			])
		elif event is GameScript.WallExhausted:
			print("No drawable tiles remain")


func _interpretation_text(decomposition: HandScript.Decomposition) -> String:
	if decomposition is HandScript.SevenPairsDecomposition:
		var pairs: PackedStringArray = []
		for pair: HandScript.Pair in (decomposition as HandScript.SevenPairsDecomposition).pairs:
			pairs.append("%d%d" % [pair.tile, pair.tile])
		return "seven pairs [%s]" % " ".join(pairs)
	var normal := decomposition as HandScript.NormalDecomposition
	var melds: PackedStringArray = []
	for sequence: HandScript.Sequence in normal.sequences:
		melds.append("%d%d%d" % [
			sequence.first_tile, sequence.first_tile + 1, sequence.first_tile + 2,
		])
	for triplet: HandScript.Triplet in normal.triplets:
		melds.append("%d%d%d" % [triplet.tile, triplet.tile, triplet.tile])
	return "normal, pair %d%d, melds [%s]" % [
		normal.pair.tile, normal.pair.tile, " ".join(melds),
	]


static func rejection_text(reason: GameScript.Rejection) -> String:
	if reason is GameScript.GameEndedRejection:
		var ended := reason as GameScript.GameEndedRejection
		if ended.phase == GameScript.Phase.WON:
			return "The game has already been won"
		return "The game has already ended"
	if reason is GameScript.UnknownActionRejection:
		return "Unknown action"
	if reason is GameScript.EmptyDrawPileRejection:
		return "No tiles remain to draw"
	if reason is GameScript.InvalidDiscardIndexRejection:
		var invalid := reason as GameScript.InvalidDiscardIndexRejection
		return "Discard index %d is outside the valid range %d-%d" % [
			invalid.index,
			invalid.minimum,
			invalid.maximum,
		]
	if reason is GameScript.IncompleteHandRejection:
		return "The hand is not complete"
	return "Action rejected"
