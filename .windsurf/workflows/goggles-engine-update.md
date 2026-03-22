---
description: Propagate goggles_db engine changes to all consumer projects (goggles_api, goggles_main, goggles_admin2)
auto_execution_mode: 2
---

# Goggles Engine Update

Use this skill after any change to `goggles_db` that must be picked up by consumer projects. This includes model changes, migrations, new strategies, decorator updates, factory changes, or version bumps.

## When to Use

- After committing and pushing changes to `goggles_db`
- After adding or modifying migrations
- After changing models, factories, commands, strategies, or decorators in the engine
- After bumping `GogglesDb::VERSION` in `lib/goggles_db/version.rb`

## Procedure

### 1. Ensure `goggles_db` Is Committed and Pushed

```bash
cd /home/steve/Projects/goggles_db
git status
git push origin master
```

The consumer projects reference `goggles_db` via Git source in their Gemfile:

```ruby
gem 'goggles_db', git: 'https://github.com/steveoro/goggles_db'
```

### 2. Update Each Consumer Project

Run the `update_engine.sh` script in each project. This executes:

```bash
GIT_LFS_SKIP_SMUDGE=1 bundle update goggles_db
```

The `GIT_LFS_SKIP_SMUDGE=1` flag skips downloading large test dump files included in the gem.

#### 2a. `goggles_api`

```bash
cd /home/steve/Projects/goggles_api
./update_engine.sh
```

#### 2b. `goggles_main`

```bash
cd /home/steve/Projects/goggles_main
./update_engine.sh
```

#### 2c. `goggles_admin2`

```bash
cd /home/steve/Projects/goggles_admin2
./update_engine.sh
```

### 3. Run Migrations (if applicable)

If the `goggles_db` change included new migrations, run them in each consumer project:

```bash
# goggles_api:
cd /home/steve/Projects/goggles_api
rails db:migrate RAILS_ENV=test

# goggles_main:
cd /home/steve/Projects/goggles_main
rails db:migrate RAILS_ENV=test

# goggles_admin2:
cd /home/steve/Projects/goggles_admin2
rails db:migrate RAILS_ENV=test
```

### 4. Verify Tests

Run the test suite in each consumer to catch any breakage:

```bash
# goggles_api (RSpec only):
cd /home/steve/Projects/goggles_api
bundle exec rspec

# goggles_main (RSpec + Cucumber):
cd /home/steve/Projects/goggles_main
bundle exec rspec
bundle exec cucumber

# goggles_admin2 (RSpec + Cucumber):
cd /home/steve/Projects/goggles_admin2
bundle exec rspec
bundle exec cucumber
```

### 5. Commit Updated Gemfile.lock

In each consumer project, the `Gemfile.lock` will have changed to reference the new `goggles_db` commit SHA:

```bash
cd /home/steve/Projects/goggles_api
git add Gemfile.lock && git commit -m "Update goggles_db engine"

cd /home/steve/Projects/goggles_main
git add Gemfile.lock && git commit -m "Update goggles_db engine"

cd /home/steve/Projects/goggles_admin2
git add Gemfile.lock && git commit -m "Update goggles_db engine"
```

## Common Issues

- **Bundle fails with gem conflict**: Check `goggles_db.gemspec` dependencies against the consumer's Gemfile. The engine pins `rails >= 6.1.7, < 7`.
- **Migration already run**: If the migration was already applied (e.g. from a previous local test), `rails db:migrate` will skip it silently.
- **Factory changes not picked up**: Run `spring stop` in the consumer project to clear cached autoloading, then retry.
- **Scenic view issues**: Ensure `scenic` and `scenic-mysql_adapter` gems are present in the consumer project's Gemfile (they are in all three).

## Deployment Note

- `goggles_api` and `goggles_main` are deployed automatically via CI (CircleCI) when tests pass on push. The Docker images are rebuilt with the updated engine.
- `goggles_admin2` runs localhost-only and doesn't have CI or automated deployment.
