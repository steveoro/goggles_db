---
description: Decision-tree guide for determining which Goggles project(s) to modify for any type of change
auto_execution_mode: 2
---

# Where to Intervene

Use this skill to determine which project(s) need changes and in what order, given a type of modification to the Goggles framework.

## Core Rule

**`goggles_db` first, then propagate.** Any change to shared structure (models, migrations, factories, strategies, decorators, commands) starts in the engine gem and flows outward.

## Decision Tree

### Database / Model Changes

| Change | Start In | Then Propagate To |
| --- | --- | --- |
| Add/rename/remove column | `goggles_db` (migration + model) | `goggles_api` (params), `goggles_main` (views), `goggles_admin2` (views + import strategies) |
| New table/model | `goggles_db` (migration + model + factory) | `goggles_api` (new endpoint), `goggles_main` (views if public), `goggles_admin2` (grids/import if needed) |
| New Scenic DB view | `goggles_db` (SQL + model) | Consumer projects only need engine update |
| Change validation/scope | `goggles_db` (model + specs) | Engine update in consumers; check for code relying on old behavior |
| New/updated factory | `goggles_db` (factory file) | Engine update in consumers (factories auto-inherited) |

### API Changes

| Change | Start In | Then Propagate To |
| --- | --- | --- |
| New API endpoint | `goggles_api` (Grape controller + specs) | `goggles_admin2` (if it calls the endpoint via `APIProxy`) |
| Modify endpoint params | `goggles_api` (controller + specs) | `goggles_admin2` (check `APIProxy` calls) |
| Auth/JWT changes | `goggles_db` (`JwtManager`) + `goggles_api` | All consumers |

### Frontend Changes

| Change | Start In | Affects |
| --- | --- | --- |
| New public page | `goggles_main` only | Controller + view + component + route + specs |
| New admin page | `goggles_admin2` only | Controller + view + component + route + specs |
| Shared decorator change | `goggles_db` (base decorator) | `goggles_main` + `goggles_admin2` (may override) |
| i18n key change | `goggles_db` (engine locales) | All consumers (may have overrides) |

### Import Pipeline Changes

| Change | Start In | Affects |
| --- | --- | --- |
| New PDF format | `goggles_admin2` only | YAML in `app/strategies/pdf_results/formats/` |
| Modify L2 converter | `goggles_admin2` only | `app/strategies/pdf_results/l2_converter.rb` |
| Modify MacroSolver | `goggles_admin2` only | `app/strategies/import/macro_solver.rb` + solvers/ |
| Modify MacroCommitter | `goggles_admin2` only | `app/strategies/import/macro_committer.rb` + committers/ |
| New crawler layout | `goggles_admin2` only | `crawler/` (Node.js) |
| Merge strategy | `goggles_admin2` only | `app/strategies/merge/` |

### Infrastructure Changes

| Change | Start In | Affects |
| --- | --- | --- |
| Docker config | `goggles_api` or `goggles_main` | Respective `Dockerfile.*` + `docker-compose.*.yml` |
| CI config | Each project independently (except `goggles_admin2`) | `.circleci/config.yml`, `config/database_ci.yml` |
| Ruby version | All projects simultaneously | `.ruby-version`, `Gemfile`, `Dockerfile.*` |
| Rails version | `goggles_db` first (gemspec) | Then all consumers (Gemfile) |
| Gem dependency | `goggles_db` (if shared) or specific project | Engine update if in `goggles_db` |

## Propagation Checklist

After any `goggles_db` change:

1. Commit and push `goggles_db`
2. In each consumer (`goggles_api`, `goggles_main`, `goggles_admin2`):
   - Run `./update_engine.sh`
   - Run `rails db:migrate RAILS_ENV=test` (if migrations added)
   - Search for references to changed code (`grep -rn`)
   - Update affected files
   - Run test suite
   - Commit `Gemfile.lock` + any code changes

## Quick Reference: Project Responsibilities

- **`goggles_db`**: Schema, models, associations, validations, scopes, factories, base decorators, shared strategies (finders, calculators, normalizers), commands, Scenic views
- **`goggles_api`**: Grape endpoints, request authorization, API docs, API-specific commands
- **`goggles_main`**: Public UI (controllers, views, components, grids, Stimulus JS), Cucumber features
- **`goggles_admin2`**: Admin UI, PDF parsing, import pipeline (solver/committer), merge strategies, JS crawler, SQL generation, API proxy
