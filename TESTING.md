# Testing

The project uses GDUnit4 6.2.3 and GDUnit4 Coverage 0.1.4.

## Unit Tests

Run all tests with the installed Godot binary:

```sh
just test
```

GDUnit writes HTML and JUnit reports under `reports/`.

## Coverage

Coverage requires the patched `gdcov` runner matching Godot 4.7. Download it
through **Project > Tools > GdUnit4 Coverage: Setup Coverage Runner**, or from
the GDUnit4 Coverage releases page. Then run:

```sh
just coverage /path/to/gdcov-4.7-stable
```

The LCOV tracefile is written to `coverage/coverage.lcov`. Coverage includes
`res://src/` and excludes tests and addons. GitHub Actions publishes both the
LCOV tracefile and a browsable HTML report.

GDUnit4 Coverage 0.1.4 is an open-beta trial and records at most 20 distinct
source files per session.
