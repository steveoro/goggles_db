---
description: Add, rename, or remove a DB column across the Goggles framework — migration, model, API, views, and tests in all affected projects
auto_execution_mode: 2
---

# Goggles Column Change

Use this skill when adding, renaming, or removing a column in the database. Because `goggles_db` is a shared engine, changes must propagate to all consumer projects.

## Prerequisites

- Identify the target table and model (all in `GogglesDb::` namespace)
- Decide the change type: **add**, **rename**, or **remove**
- Check which consumer projects reference the affected column

## Step-by-step Procedure

### Phase 1 — `goggles_db` (Engine Gem)

All DB structure changes start here: `/home/steve/Projects/goggles_db`

#### 1.1 Generate Migration

```bash
# From goggles_db project root:
cd /home/steve/Projects/goggles_db
rails generate migration AddColumnNameToTableName column_name:type
# or for rename:
rails generate migration RenameOldColumnToNewColumnInTableName
```

Write the migration in `db/migrate/`. Follow existing conventions:

- Use `reversible` or `change` methods
- For renames, use `rename_column :table_name, :old_name, :new_name`
- For additions, include index if the column is a foreign key
- Update `GogglesDb::Version::DB` in `lib/goggles_db/version.rb` if this is a structural change

#### 1.2 Run Migration

```bash
cd /home/steve/Projects/goggles_db
rails db:migrate RAILS_ENV=test
```

The schema file will update at `spec/dummy/db/schema.rb`.

#### 1.3 Update Model

Edit the model in `app/models/goggles_db/<model_name>.rb`:

- Add/update validations for new columns
- Update `belongs_to` / `has_many` if it's a foreign key
- Update scopes that reference the old column name (for renames)
- Update `single_associations` / `multiple_associations` overrides if needed
- Update `minimal_attributes` if the column should appear in JSON output

#### 1.4 Update Factory

Edit the factory in `spec/factories/goggles_db/<table_name>.rb`:

- Add the new column with a sensible default or FFaker value
- Rename the attribute for renames
- Remove the attribute for deletions

#### 1.5 Update Decorator (if applicable)

Check `app/decorators/` for any decorator that references the column. Update display methods.

#### 1.6 Update Specs

Edit specs in `spec/models/goggles_db/<model_name>_spec.rb`:

- Update shared examples and attribute checks
- Add/modify validation specs for new columns
- Update any scope specs referencing the old column

#### 1.7 Run Tests

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/models/goggles_db/<model_name>_spec.rb
```

#### 1.8 Commit & Push

```bash
cd /home/steve/Projects/goggles_db
# Bump VERSION / Version::PATCH if needed
git add -A && git commit -m "Add/Rename/Remove <column> on <table>"
git push origin master
```

### Phase 2 — `goggles_api` (API Layer)

Path: `/home/steve/Projects/goggles_api`

#### 2.1 Update Engine

```bash
cd /home/steve/Projects/goggles_api
./update_engine.sh
rails db:migrate RAILS_ENV=test
```

#### 2.2 Update API Endpoint

Edit the Grape API file in `app/api/goggles/<model_name>s_api.rb`:

- **For `params` blocks**: add/rename/remove the parameter declaration
- **For `declared(params)`**: ensure the new column is included in mass-assignment
- **For filtering**: update `filtering_hash_for` / `filtering_like_for` arrays
- **For Select2 format**: update the lambda if the renamed/new column affects display

Reference pattern from `app/api/goggles/swimmers_api.rb`:

```ruby
params do
  requires :id, type: Integer, desc: 'Model ID'
  optional :new_column, type: String, desc: 'description'
end
```

#### 2.3 Update API Blueprint (if applicable)

Edit docs in `blueprint/` to document the new/changed parameter.

#### 2.4 Update Request Specs

Edit specs in `spec/api/goggles/<model_name>s_api_spec.rb`:

- Add the new param to POST/PUT test payloads
- Verify the column appears in GET responses
- For renames: update all references

#### 2.5 Run Tests

```bash
cd /home/steve/Projects/goggles_api
bundle exec rspec spec/api/goggles/<model_name>s_api_spec.rb
```

### Phase 3 — `goggles_main` (Public Frontend)

Path: `/home/steve/Projects/goggles_main`

#### 3.1 Update Engine

```bash
cd /home/steve/Projects/goggles_main
./update_engine.sh
rails db:migrate RAILS_ENV=test
```

#### 3.2 Search for Column References

```bash
# Find all references to the old column name:
grep -rn 'old_column_name' app/ spec/ features/ --include='*.rb' --include='*.haml' --include='*.js'
```

#### 3.3 Update Views, Components, Grids

- **HAML views** in `app/views/` — update any direct column references
- **ViewComponents** in `app/components/` — update component initializers and templates
- **Datagrid definitions** in `app/grids/` — update column declarations
- **Decorators** in `app/decorators/` — update display helpers
- **Strategies** in `app/strategies/` — update any logic referencing the column

#### 3.4 Update Specs

- RSpec in `spec/`
- Cucumber features in `features/`

#### 3.5 Run Tests

```bash
cd /home/steve/Projects/goggles_main
bundle exec rspec
bundle exec cucumber
```

### Phase 4 — `goggles_admin2` (Admin Tool)

Path: `/home/steve/Projects/goggles_admin2`

#### 4.1 Update Engine

```bash
cd /home/steve/Projects/goggles_admin2
./update_engine.sh
rails db:migrate RAILS_ENV=test
```

#### 4.2 Search for Column References

```bash
grep -rn 'old_column_name' app/ spec/ features/ --include='*.rb' --include='*.haml' --include='*.js'
```

Pay special attention to:

- **Import strategies** in `app/strategies/import/` — MacroSolver and MacroCommitter reference columns by name
- **Merge strategies** in `app/strategies/merge/` — column references in deduplication logic
- **PDF parser** in `app/strategies/pdf_results/` — field mappings to column names
- **Grids** in `app/grids/` — 21 Datagrid definitions
- **Components** in `app/components/` — 65 ViewComponents
- **Services** in `app/services/`

#### 4.3 Update Specs

```bash
cd /home/steve/Projects/goggles_admin2
bundle exec rspec
bundle exec cucumber
```

## Checklist Summary

- [ ] Migration in `goggles_db`
- [ ] Model updated (validations, scopes, associations)
- [ ] Factory updated
- [ ] Decorator updated (if applicable)
- [ ] `goggles_db` specs green
- [ ] `goggles_db` committed & pushed
- [ ] `goggles_api` engine updated + migration run
- [ ] API endpoint params updated
- [ ] API specs green
- [ ] `goggles_main` engine updated + migration run
- [ ] Views/components/grids updated
- [ ] `goggles_main` specs green
- [ ] `goggles_admin2` engine updated + migration run
- [ ] Import/merge/parser strategies updated
- [ ] `goggles_admin2` specs green
