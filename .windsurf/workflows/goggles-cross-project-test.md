---
description: Run the relevant test suites across Goggles projects after a shared change — RSpec, Cucumber, Guard, CI
auto_execution_mode: 2
---

# Cross-Project Testing

Use this skill after making a change in `goggles_db` (or any shared component) that may affect multiple consumer projects. It covers which tests to run, in what order, and how to use Guard for continuous feedback.

## Test Stack per Project

| Project | RSpec | Cucumber | Guard | CI |
| --- | --- | --- | --- | --- |
| `goggles_db` | Yes | No | Yes | CircleCI |
| `goggles_api` | Yes | No | Yes | CircleCI |
| `goggles_main` | Yes | Yes | Yes | CircleCI |
| `goggles_admin2` | Yes | Yes | Yes | None (localhost-only) |

## Quick Full Suite Commands

```bash
# goggles_db:
cd /home/steve/Projects/goggles_db && bundle exec rspec

# goggles_api:
cd /home/steve/Projects/goggles_api && bundle exec rspec

# goggles_main:
cd /home/steve/Projects/goggles_main && bundle exec rspec
cd /home/steve/Projects/goggles_main && bundle exec cucumber

# goggles_admin2:
cd /home/steve/Projects/goggles_admin2 && bundle exec rspec
cd /home/steve/Projects/goggles_admin2 && bundle exec cucumber
```

## Targeted Testing Strategy

Not every change requires running all suites everywhere. Use this guide:

### Model / Migration Changes (goggles_db)

```bash
# 1. Test the changed model:
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/models/goggles_db/<model_name>_spec.rb

# 2. Test the factory:
bundle exec rspec spec/factories/

# 3. In each consumer, test anything that uses the model:
cd /home/steve/Projects/goggles_api
bundle exec rspec spec/api/goggles/<model_name>s_api_spec.rb

cd /home/steve/Projects/goggles_main
bundle exec rspec spec/ -t <model_name>  # if tagged
```

### Decorator Changes

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/decorators/

# Check overrides in consumers:
cd /home/steve/Projects/goggles_main
bundle exec rspec spec/decorators/
cd /home/steve/Projects/goggles_admin2
bundle exec rspec spec/decorators/
```

### Strategy Changes (goggles_db)

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/strategies/
```

### API Endpoint Changes

```bash
cd /home/steve/Projects/goggles_api
bundle exec rspec spec/api/goggles/<endpoint>_spec.rb
```

### Import Pipeline Changes (goggles_admin2)

```bash
cd /home/steve/Projects/goggles_admin2
bundle exec rspec spec/strategies/import/
bundle exec rspec spec/strategies/pdf_results/
```

### View / Component Changes

```bash
# goggles_main:
cd /home/steve/Projects/goggles_main
bundle exec rspec spec/components/
bundle exec rspec spec/views/
bundle exec cucumber features/<feature_name>.feature

# goggles_admin2:
cd /home/steve/Projects/goggles_admin2
bundle exec rspec spec/components/
bundle exec rspec spec/views/
bundle exec cucumber features/<feature_name>.feature
```

## Using Guard

Each project has a `Guardfile` for auto-running tests on file changes. Start Guard with:

```bash
cd /home/steve/Projects/<project>
bundle exec guard
```

Guard watches for file changes and runs the relevant specs automatically. It also runs RuboCop, Brakeman, and HAML-lint checks where configured.

To run all specs within Guard, press `Enter` at the Guard prompt.

## CI: CircleCI

All projects except `goggles_admin2` use CircleCI for continuous integration. Configuration lives in `.circleci/config.yml` in each project root.

- `config/database_ci.yml` — CI database config (used by CircleCI)
- `config/database.semaphore_2.yml` — Legacy Semaphore 2 config (kept for reference, no longer active)

CircleCI runs automatically on push to `master`. The `goggles_db` pipeline runs: Rubocop → Brakeman → Zeitwerk check → RSpec (models, commands, decorators, strategies, validators in parallel jobs).

`goggles_admin2` has no CI pipeline — it runs localhost-only and is tested manually.

To simulate the CI environment locally:

```bash
# Match the CI test runner output format:
RAILS_ENV=test bundle exec rspec --format RspecJunitFormatter --out tmp/rspec_results.xml
```

## Common Test Issues

- **Spring caching stale code**: Run `spring stop` in the project, then retry.
- **DB not migrated**: Run `rails db:migrate RAILS_ENV=test` after engine updates.
- **Factory not found**: After `goggles_db` changes, run `./update_engine.sh` first.
- **Flaky Cucumber tests**: Selenium-based tests can be timing-sensitive. Re-run isolated failures.
- **N+1 query detection**: `n_plus_one_control` and `Prosopite`/`Bullet` are active in test/development. Fix detected N+1s before committing.
