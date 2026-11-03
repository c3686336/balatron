extends GutTest

const CliScript := preload("res://src/cli.gd")
const GameScript := preload("res://src/backend/game.gd")


func test_frontend_converts_rejection_types_to_text() -> void:
	assert_eq(
		CliScript.rejection_text(GameScript.GameEndedRejection.new(GameScript.Phase.WON)),
		"The game has already been won",
	)
	assert_eq(
		CliScript.rejection_text(GameScript.UnknownActionRejection.new()),
		"Unknown action",
	)
	assert_eq(
		CliScript.rejection_text(GameScript.EmptyDrawPileRejection.new()),
		"No tiles remain to draw",
	)
	assert_eq(
		CliScript.rejection_text(GameScript.InvalidDiscardIndexRejection.new(14, 0, 13)),
		"Discard index 14 is outside the valid range 0-13",
	)
	assert_eq(
		CliScript.rejection_text(GameScript.IncompleteHandRejection.new()),
		"The hand is not complete",
	)
