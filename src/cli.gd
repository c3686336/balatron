extends SceneTree

const ActionScript := preload("res://src/backend/action.gd")
const GameScript := preload("res://src/backend/game.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var seed := _read_seed()
	var state: GameScript.State = GameScript.new_game(seed)
	print("Balatron CLI (seed %d)" % seed)
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


func _read_seed() -> int:
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty() and arguments[0].is_valid_int():
		return arguments[0].to_int()
	return int(Time.get_unix_time_from_system())


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
			print("Rejected: %s" % (event as GameScript.ActionRejected).reason)
		elif event is GameScript.TileDiscarded:
			print("Discarded %d" % (event as GameScript.TileDiscarded).tile.value)
		elif event is GameScript.TileDrawn:
			print("Drew %d" % (event as GameScript.TileDrawn).tile.value)
		elif event is GameScript.WallExhausted:
			print("No drawable tiles remain")
