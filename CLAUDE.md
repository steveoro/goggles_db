# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`goggles_db` is a mountable, isolated Rails Engine (`GogglesDb`, Ruby 3.4.7 / Rails 8.1+ / MariaDB) holding the DB structure and base models shared by the Goggles framework apps (`goggles_main`, API, etc.). It is not a standalone app: specs run against the embedded app in `spec/dummy`. When run from the repo root, engine rake tasks need the `app:` prefix (e.g. `rails app:db:rebuild`).

`AGENTS.md` holds the mandatory rules for DB structure changes (this repo is the source of truth; migrations/views must be copied to `goggles_main` under `db/migrate` and `db/views`, and the test dump must be regenerated). Follow it.

## Commands

```bash
bundle exec rspec                         # full suite
bundle exec rspec spec/models/goggles_db/swimmer_spec.rb       # single file
bundle exec rspec spec/models/goggles_db/swimmer_spec.rb:42    # single example
guard                                     # continuous test runner (Enter reruns everything)
bundle exec rubocop                       # lint (config in .rubocop.yml / .rubocop_todo.yml)
bundle exec brakeman -Aq                  # run before pushing

RAILS_ENV=test rails app:db:rebuild       # restore test DB from spec/dummy/db/dump/test.sql.bz2
RAILS_ENV=test bundle exec rake db:dump   # (from spec/dummy) regenerate the test dump after structure changes
rails app:db:rebuild from=test to=development
```

The use of the RVM gemset is expected (see AGENTS.md).

## Testing model

- Tests rely on a pre-populated, anonymized fixture DB restored from `spec/dummy/db/dump/test.sql.bz2` (stored in Git LFS; use `GIT_LFS_SKIP_SMUDGE=1 bundle update goggles_db` from consumer projects). The DB is **not** cleared between runs; examples use transactional fixtures.
- Factories live in `spec/factories` (FactoryBot, also used by consumers).
- Any migration or Scenic view change requires migrating the test DB and regenerating the dump in the same change.

## Architecture

- `lib/goggles_db/engine.rb` – Engine definition; adds `lib/extensions`, `lib/wrappers`, `app/components` to eager load paths. `lib/goggles_db/version.rb` holds the gem version (bumped in dedicated commits).
- `app/models/goggles_db/` – ActiveRecord models, namespaced and including:
  - `abstract_*` base classes (lookup entities, meetings, results, result rows, laps, best-results) shared by concrete models.
  - Models backed by **Scenic views** (`best_*`, `meeting_*_result_rows`, `goggles_cup_3y_base_timings`, `last_seasons_ids`, ...). View SQL is versioned as `db/views/<name>_vNN.sql`; changing a view means adding a new version file plus a migration, never editing an old version.
  - `data_import_*` models for staging imported data.
  - Concerns in `app/models/concerns` (`localizable`, `timing_manageable`).
- `app/commands/` – `Cmd*` service objects (find DB entity, clone meeting structure, create reservation, ...).
- `app/strategies/` – finders (`db_finders`, `timing_finders`), `normalizers` (e.g. coded names), calculators (score), grant/manager checkers, `JwtManager`.
- `app/services/`, `app/decorators/` (Draper), `app/components/` (ViewComponent), `app/validators/`.
- `lib/tasks/*.rake` – DB dump/rebuild/reset/check, anonymization and data-normalization tasks (cities, coded names, counter caches, lap timings, relay laps, reservations, plus codes).
- `db/migrate/` – timestamped migrations (including DB version bumps such as `update_db_version_to_NNNNN`).
- User auth uses Devise (the host app must mount the Engine to get the routes).

## Conventions

- Rubocop with rails/rspec/performance/factory_bot plugins; files use `# frozen_string_literal: true`.
- Update `CHANGELOG.md` / version bump follow existing commit patterns (`chore: bump version to ...`); commit messages use conventional prefixes (`feat(...)`, `fix(...)`, `chore:`).
