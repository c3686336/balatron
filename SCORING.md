# Scoring

`src/backend/scoring.gd` owns pure bonus-rank scoring. Game state changes remain in `Game.update()`.

## Evaluation

```gdscript
var candidates := Hand.decompose(tile_counts)
var result := Scoring.evaluate(tile_counts, bonus_rank, candidates)
```

Inputs are nine valid rank counts, a bonus rank from 1 through 9, and caller-validated complete-hand decompositions. An empty candidate list returns `null`; the game translates that into `IncompleteHandRejection`.

A result contains:

- `selected_decomposition`: an eligible interpretation of the winning hand.
- `bonus_rank_contribution.rank` and `.han`: the bonus rank and its matching-tile count.
- `han`: total awarded han.
- `points`: `1 << han`.

All current scoring depends on rank counts, so every eligible interpretation scores equally. The evaluator uses one eligible interpretation without repeatedly calculating the same score. No item hooks or hypothetical future scoring stages are introduced.

Evaluation changes no input, state, or random generator. Returned objects and their shared decomposition are read-only by convention. Independent evaluations have independent contribution/result objects.

## Accepted wins

The game evaluates before copying and committing the accepted win. `State.han` and `State.score` remain the stored final totals.

`TsumoDeclared` contains the original eligible `decompositions` and the authoritative `scoring` result. Event consumers read `event.scoring.han` and `event.scoring.points`; the former duplicate event-level `han`/`score` fields are removed. The CLI prints the contribution and final arithmetic directly from this result.

The full stock wall, dealing, discards, rejection rules, and final-draw behavior are unchanged. With no bonus-rank tiles a winning hand scores one point; four bonus-rank tiles score sixteen.

## Verification

Executed on Godot 4.7.2:

```sh
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gexit
printf 'd 13\nt\n' | godot --headless -s src/cli.gd -- 12345
```

All 34 GUT tests passed. The CLI accepted tsumo and displayed bonus rank 9 contributing one han, with a two-point total. The initial import emitted the existing missing-coverage-extension diagnostics; tests and the CLI completed successfully.

## Independent review branch

This branch starts directly from `main` and has no dependency on `feat/yaku-items`. Both changes touch accepted-tsumo processing and presentation, so merging both requires reconciling those sections. Preserve pure candidate evaluation and a single authoritative accepted score when integrating item contributions; do not restore duplicate event totals or score separately in the UI.
