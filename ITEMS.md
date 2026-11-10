# Equipped yaku items

This adds stateless passive items to the existing single-hand game. The combined `feat/yaku-items` branch includes the pure scoring refactor and is ready for one PR against `main`.

## Starting loadout

List the catalog:

```sh
godot --headless -s src/cli.gd -- --list-items
```

Pass a seed followed by stable item IDs:

```sh
godot --headless -s src/cli.gd -- 3 tanyao iipeikou chiitoitsu toitoi sanankou
```

The loadout is fixed when the hand is dealt. There are no mid-hand equipment changes, slot limits, purchases, active effects, or run-progression rules. With no item IDs, play and scoring retain their original behavior. Unknown IDs and repeated IDs are rejected before dealing; the CLI exits with status 1.

| ID | Condition in the selected interpretation | Bonus han |
|---|---|---|
| `tanyao` | No rank 1 or 9 anywhere in the winning hand, including the drawn tile | 1 |
| `iipeikou` | At least one pair of identical sequences in a normal decomposition | 1 |
| `chiitoitsu` | Seven distinct pairs | 2 |
| `toitoi` | Four triplets | 2 |
| `sanankou` | At least three concealed triplets | 2 |

Every current hand is concealed and wins by tsumo. There is no kan action or exposed-meld system. Toitoi and Sanankou can both pay on a four-triplet interpretation when both items are equipped. Each equipped item pays at most once, including Iipeikou when there are multiple duplicated sequences. Traditional fu, waits, yakuman, and additional automatic yaku are not introduced.

## Scoring

Bonus-rank matching tiles still supply the base han. Equipped matching yaku add their han, and points remain `1 << total_han`.

`Scoring.evaluate()` independently scores every eligible decomposition and selects the best whole result. Bonuses from incompatible interpretations are never combined. For example, with only Iipeikou and Chiitoitsu equipped, `11223344556677` earns Chiitoitsu's two han rather than combining it with a normal interpretation's Iipeikou.

The CLI displays the chosen interpretation, bonus-rank han, awarded items, and final arithmetic. An ordinary complete hand may declare tsumo even when none of its equipped yaku matches.

The full stock tile supply and 22 initial live draws are unchanged. No tiles are reserved or taken aside.

## Backend API and ownership

```gdscript
var equipped: Array[String] = ["tanyao", "chiitoitsu"]
var state := Game.new_game(12345, equipped)
```

`new_game` returns `null` for an invalid loadout. `ItemCatalog.loadout_error()` returns the reason. The state constructor and `State.copy()` independently copy the inventory array, so editing a caller's array or another snapshot cannot change an existing state's loadout. As with other state fields, callers should treat a handed-off state as immutable.

`ItemCatalog` registers shared `Item` definitions. `Item` owns read-only ID, display-name, and description properties; `YakuItem` adds han and the abstract `matches(counts, decomposition)` contract. Each concrete yaku owns its metadata and matching rule in `src/backend/items/yaku/`. Definitions contain no owned mutable item state. `ids()`, `name_for()`, and `description_for()` support presentation.

`ItemCatalog.contributions_for(counts, decomposition, loadout)` returns typed contributions for one complete-hand interpretation. Each contribution identifies its `item_id` and awarded `han`. It performs matching only: candidate selection, total han, and points belong to the pure scoring service.

Accepted wins expose all eligible decompositions and one authoritative result at `TsumoDeclared.scoring`. Use its `selected_decomposition`, `bonus_rank_contribution`, `item_contributions`, `han`, and `points`. The game commits evaluated totals once; no alternate item-evaluation result or duplicate event totals remain. See [SCORING.md](SCORING.md).

## Adding a yaku

Create a subclass of `YakuItem`, initialize its metadata through `super(...)`, implement its pure `matches()` method, and register its instance in `ItemCatalog._build_definitions()`. The catalog dispatches matching to registered `YakuItem` instances; no central ID switch or per-yaku condition is required in the catalog or scorer.

Matching receives a complete-hand interpretation and must not mutate counts, the interpretation, or the shared definition. The abstract contract has no default false-return implementation, so missing rule implementations are rejected by GDScript.

The inventory still stores stable definition IDs. A shared definition is not an owned item instance: charges or other mutable per-owned state would belong in the game state, not on these shared definitions.

## Per-tile upgrades: current boundary

The item hierarchy makes item behavior extensible; it does not yet implement individual-tile upgrades. Each physical copy is a separate `Tile` object, but `Tile` currently contains only its rank, and `Tile.copy()` creates a new object with that rank. Scoring receives rank counts rather than physical tiles, so it cannot distinguish one upgraded 5 from the other three 5s.

A per-tile upgrade system would need:

- Stable tile IDs preserved by copying, plus per-copy upgrade data copied with the tile. Godot object instance IDs are not stable across state snapshots.
- Physical hand tiles supplied to scoring alongside rank counts. Ordinary hand decomposition can remain rank-based.
- A defined application scope: hand-wide tile bonuses can inspect the physical tiles directly; a bonus tied to a particular meld must also determine which physical copies occupy that meld when several copies share a rank.
- An explicit lifetime. Within-hand upgrades can travel with the tile between zones. Upgrades that survive reshuffling must be reapplied to stable tile identities when dealing, rather than lost through the current fresh-stock factory.

Persisting upgrade identity does not require changing the full-wall composition or taking tiles aside. Rank-changing or wildcard upgrades would separately affect hand legality; those are not equivalent to a per-copy scoring bonus.

No tile-upgrade API, persistence, or placeholder implementation is added by this PR.


## Verification

The integrated implementation passed all 44 GUT tests on Godot 4.7.2:

```sh
godot --headless -s addons/gut/gut_cmdln.gd -gexit
printf 't\n' | godot --headless -s src/cli.gd -- 3 tanyao iipeikou chiitoitsu toitoi sanankou
printf 'd 13\nt\n' | godot --headless -s src/cli.gd -- 12345
```

Regression coverage includes incompatible candidate scoring, terminal exclusion in the drawn position, distinct-pair rules, one-time Iipeikou payment, three-versus-four-triplet conditions, pure previews, inventory snapshot isolation, and invalid starting loadouts.

The equipped CLI scenario accepted `123 / 123 / 678 / 999` with pair `66`, awarded Iipeikou, and displayed one han and two points. The no-item scenario also completed with the original one-han, two-point result and a full contribution explanation.
