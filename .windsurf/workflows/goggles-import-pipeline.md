---
description: End-to-end import pipeline — crawler, PDF parse, L2 conversion, MacroSolver, MacroCommitter, SQL push via API
auto_execution_mode: 2
---

# Goggles Import Pipeline

Use this skill to understand or debug the full data import flow in `goggles_admin2`. This covers every stage from raw data collection to committing results on the remote server.

## Pipeline Overview

```text
 ┌─────────────────────────────────────────────────────────┐
 │  DATA COLLECTION (two paths)                            │
 │                                                         │
 │  Path A: JS Crawler ──► HTML scrape ──► JSON (L2)       │
 │  Path B: PDF files  ──► text extract ──► FormatParser   │
 │                         ──► L2Converter ──► JSON (L2)   │
 └─────────────┬───────────────────────────────┬───────────┘
               │                               │
               ▼                               ▼
 ┌─────────────────────────────────────────────────────────┐
 │  DATA PROCESSING                                        │
 │                                                         │
 │  JSON (L2 format) ──► Import::MacroSolver               │
 │    (entity resolution: find or build DB rows)           │
 │                                                         │
 │  MacroSolver ──► Import::MacroCommitter                 │
 │    (commit entities in dependency order, generate SQL)  │
 └─────────────────────────┬───────────────────────────────┘
                           │
                           ▼
 ┌─────────────────────────────────────────────────────────┐
 │  OUTPUT                                                 │
 │                                                         │
 │  SQL batch file ──► APIProxy ──► goggles_api (remote)   │
 │  (wrapped in a single transaction)                      │
 └─────────────────────────────────────────────────────────┘
```

## Stage 1: Data Collection

### Path A — JS Crawler (HTML scraping)

- **Location**: `/home/steve/Projects/goggles_admin2/crawler/`
- **Technology**: Node.js, Cheerio, Express
- **Input**: Official result websites (e.g. Microplus timing pages)
- **Output**: JSON files in `crawler/data/results.new/` (already in L2 format)

The crawler scrapes structured HTML result pages and outputs JSON files with `layoutType: 2`. These are ready for the MacroSolver without conversion.

File lifecycle: `results.new/` → (processed) → `results.done/` or `results.sent/`

### Path B — PDF Processing

- **Location**: `/home/steve/Projects/goggles_admin2/app/strategies/pdf_results/`
- **Input**: PDF files (converted to text) in `crawler/data/pdfs/`
- **Output**: JSON (L2 format) via `L2Converter`

#### Step B1: PDF → Text

PDFs are converted to plain text externally (e.g. via `pdftotext`). The text file is then fed to `FormatParser`.

#### Step B2: FormatParser (layout detection + parsing)

`PdfResults::FormatParser` (`format_parser.rb`):

1. Loads all YAML format definitions from `app/strategies/pdf_results/formats/`
2. Splits text into pages (ASCII form-feed `\f`)
3. Tries each format against the first page — first valid match wins
4. Parses remaining pages using the winning format family (subformats tried per-page)
5. Produces a `root_dao` (tree of `ContextDAO` objects)

#### Step B3: L2Converter (DAO → JSON hash)

`PdfResults::L2Converter` (`l2_converter.rb`):

1. Takes the `root_dao` and a `GogglesDb::Season`
2. Walks the DAO tree, mapping field names to L2 hash keys
3. Converts timing strings to structured data
4. Resolves categories using `CategoriesCache`
5. Outputs a Hash in the same L2 format the crawler produces

## Stage 2: MacroSolver (Entity Resolution)

- **Location**: `/home/steve/Projects/goggles_admin2/app/strategies/import/macro_solver.rb`
- **Input**: L2 JSON hash + `season_id`
- **Output**: Enriched data hash with DB rows (found or newly built) for each entity

The MacroSolver scans the L2 hash and for each entity:

1. Searches the DB for an existing matching row (using `GogglesDb::DbFinders`)
2. If not found, builds a new `Import::Entity` wrapper with the parsed attributes
3. Resolves "bindings" — foreign key references between entities (e.g. a SwimmingPool's `city_id`)

### Entity resolution order

The solver processes entities in this order:

1. **Meeting** — find by `code` + `season_id`, or build new
2. **Cities** — find by name + country_code, or build new
3. **SwimmingPools** — find by name/nick_name + city, or build new
4. **MeetingSessions** — find by meeting + session_order, or build new
5. **Teams** — find by name (fuzzy match), or build new
6. **TeamAffiliations** — find by team + season, or build new
7. **Swimmers** — find by complete_name + year_of_birth (fuzzy match), or build new
8. **Badges** — find by swimmer + team + season, or build new
9. **MeetingEvents** — find by session + event_type + heat_type
10. **MeetingPrograms** — find by event + category_type + gender_type
11. **MeetingIndividualResults** — find by program + swimmer + team
12. **MeetingRelayResults** — find by program + team
13. **Laps** / **MeetingRelaySwimmers** — child rows of results

### Key sub-strategies

- `app/strategies/import/solvers/` — per-entity solver logic
- `app/strategies/import/adapters/` — data format adapters
- `app/strategies/import/entity.rb` — `Import::Entity` wrapper (holds row + bindings)
- `app/strategies/import/category_computer.rb` — resolves category from age + gender

## Stage 3: MacroCommitter (Commit + SQL Generation)

- **Location**: `/home/steve/Projects/goggles_admin2/app/strategies/import/macro_committer.rb`
- **Input**: A `MacroSolver` instance with resolved entities
- **Output**: Committed DB rows + SQL log

The MacroCommitter processes the solver's data in strict dependency order via `commit_all`:

```text
commit_meeting
  → check_and_commit_calendar
  → commit_cities
  → commit_pools
  → commit_sessions
  → commit_teams_and_affiliations  (includes commit_affiliations)
  → commit_swimmers_and_badges     (includes commit_badges)
  → commit_events
  → commit_programs
  → commit_ind_results             (includes commit_laps)
  → commit_rel_results             (includes commit_relay_swimmers, commit_relay_laps)
  → commit_team_scores
```

For each entity, `commit_and_log`:

1. Compares the model row with the DB using `difference_with_db`
2. Creates (INSERT) or updates (UPDATE) the row
3. Appends the SQL statement to `@sql_log` via `SqlMaker`
4. Replaces the `Import::Entity` wrapper with the actual committed model row

The entire commit is wrapped in an `ActiveRecord::Base.transaction`.

Progress is broadcast via ActionCable (`ImportStatusChannel`).

## Stage 4: SQL Push via API

- **`SqlMaker`** (`app/strategies/sql_maker.rb`) — generates replayable INSERT/UPDATE SQL statements from ActiveRecord rows
- **`APIProxy`** (`app/strategies/api_proxy.rb`) — singleton REST client that sends the SQL batch to `goggles_api`

The SQL batch is wrapped in a transaction:

```sql
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
-- (all INSERT/UPDATE statements)
COMMIT;
```

**Critical prerequisite**: The localhost DB must be in sync with the remote DB. The SQL uses explicit IDs, so any ID mismatch between local and remote will cause failures.

## Debugging Tips

- **Check solver output**: After `MacroSolver.new(...)`, inspect `solver.data` to see which entities were resolved vs. created
- **Check committer SQL**: After `committer.commit_all`, inspect `committer.sql_log` for the generated SQL
- **ActionCable progress**: The commit broadcasts progress to `ImportStatusChannel` — check the browser console
- **Retry flag**: If `data['sections']` contains any section with a `retry` key, the solver flags `@retry_needed`
- **Category resolution failures**: Check `CategoriesCache` — if the season doesn't have the expected `CategoryType` rows, results won't map correctly

## Key Files Reference

| Component | Path |
| --- | --- |
| JS Crawler | `crawler/` (Node.js) |
| Crawler output | `crawler/data/results.new/` |
| PDF format YAMLs | `app/strategies/pdf_results/formats/` |
| FormatParser | `app/strategies/pdf_results/format_parser.rb` |
| LayoutDef | `app/strategies/pdf_results/layout_def.rb` |
| ContextDef | `app/strategies/pdf_results/context_def.rb` |
| L2Converter | `app/strategies/pdf_results/l2_converter.rb` |
| CategoriesCache | `app/strategies/pdf_results/categories_cache.rb` |
| MacroSolver | `app/strategies/import/macro_solver.rb` |
| MacroCommitter | `app/strategies/import/macro_committer.rb` |
| Import::Entity | `app/strategies/import/entity.rb` |
| Per-entity solvers | `app/strategies/import/solvers/` |
| Per-entity committers | `app/strategies/import/committers/` |
| SqlMaker | `app/strategies/sql_maker.rb` |
| APIProxy | `app/strategies/api_proxy.rb` |

All paths relative to `/home/steve/Projects/goggles_admin2/`.
