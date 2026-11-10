# Scoring

`src/backend/scoring.gd` owns pure score evaluation and candidate selection. `ItemCatalog` dispatches passive matching to registered `YakuItem.matches()` implementations; game state changes remain in `Game.update()`.

## Evaluation

```gdscript
var candidates := Hand.decompose(tile_counts)
var result := Scoring.evaluate(tile_counts, bonus_rank, candidates, equipped_items)
```

Inputs are nine valid rank counts, a bonus rank from 1 through 9, caller-validated complete-hand decompositions, and an optional equipped-item ID list. An empty candidate list returns `null`; the game translates that into `IncompleteHandRejection`.

A result contains:

- `selected_decomposition`: the winning eligible interpretation.
- `bonus_rank_contribution.rank` and `.han`: the bonus rank and its matching-tile count.
- `item_contributions`: the matched equipped items and their awarded han for that interpretation.
- `han`: bonus-rank han plus item han.
- `points`: `1 << han`.

Each candidate is evaluated independently. The highest total han wins, which also maximizes the current exponential score. Incompatible interpretations never pool their item rewards. With no equipped items all interpretations score equally, so the evaluator uses one eligible interpretation without repeatedly calculating the same score.

`ItemCatalog.contributions_for(counts, decomposition, equipped_items)` matches one candidate through the concrete yaku classes. It does not select candidates or calculate final points. There is no central per-item switch, competing item-specific score result, or second scoring path.

Evaluation changes no input, state, inventory, or random generator. Returned objects and their shared decomposition are read-only by convention. Independent evaluations have independent result and contribution objects.

## Accepted wins

The game evaluates before copying and committing the accepted win. `State.han` and `State.score` store the final totals.

`TsumoDeclared` contains all eligible `decompositions` and one authoritative `scoring` result. Consumers read `event.scoring.han`, `.points`, `.selected_decomposition`, `.bonus_rank_contribution`, and `.item_contributions`. Duplicate event-level totals and the former item-evaluation representation are removed.

The CLI prints the chosen interpretation, bonus-rank contribution, item contributions, and final arithmetic from that result. Presentation does not calculate another score.

The full stock wall, dealing, discards, rejection rules, and final-draw behavior are unchanged. With no equipped items, zero bonus-rank tiles score one point and four score sixteen.

## Verification

The combined branch passed all 44 GUT tests on Godot 4.7.2:

```sh
godot --headless -s addons/gut/gut_cmdln.gd -gexit
printf 't\n' | godot --headless -s src/cli.gd -- 3 tanyao iipeikou chiitoitsu suuanko sanankou
printf 'd 13\nt\n' | godot --headless -s src/cli.gd -- 12345
```

The first CLI scenario awarded Iipeikou for one han and two points; the second preserved the no-item bonus-rank result of one han and two points. On a fresh checkout, import the project with `godot --headless --import` before running GUT.

`feat/yaku-items` includes the scoring refactor and the integrated item implementation for a single PR against `main`. See [ITEMS.md](ITEMS.md) for the catalog and loadout interface.
