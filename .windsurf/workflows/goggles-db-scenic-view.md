---
description: Add or update a Scenic DB view in goggles_db — SQL definition, migration, read-only model, and specs
auto_execution_mode: 2
---

# Scenic DB View

Use this skill when adding or updating a Scenic database view in `goggles_db`. Views are read-only aggregated queries backed by SQL definitions, exposed as ActiveRecord models.

## Background

- SQL definitions live in `/home/steve/Projects/goggles_db/db/views/`
- Models inherit from `AbstractBestResult` (in `app/models/goggles_db/abstract_best_result.rb`)
- Scenic gem + `scenic-mysql_adapter` handle view creation/updates
- Existing views: `Best50mResult`, `Best50And100Result`, `Best50And100Result5y`, `BestSwimmer3yResult`, `BestSwimmer5yResult`, `BestSwimmerAllTimeResult`, `LastSeasonId`

## Step-by-step Procedure

### 1. Write the SQL Definition

Create the SQL file in `db/views/`:

```text
db/views/<view_name>_v01.sql
```

Naming: `<snake_case_view_name>_v<version_number>.sql` (e.g. `best_50m_results_v04.sql`).

Follow the existing CTE pattern:

```sql
-- CTE for filtering seasons/constraints
WITH FilteredData AS (
  SELECT ...
  FROM meeting_individual_results mir
  JOIN meeting_programs mp ON mp.id = mir.meeting_program_id
  JOIN meeting_events me ON me.id = mp.meeting_event_id
  JOIN meeting_sessions ms ON ms.id = me.meeting_session_id
  JOIN meetings m ON m.id = ms.meeting_id
  JOIN seasons se ON se.id = m.season_id
  -- ... more joins as needed
  WHERE mir.disqualified = false
    AND (mir.minutes * 6000 + mir.seconds * 100 + mir.hundredths) > 0
),
-- CTE for ranking
RankedResults AS (
  SELECT ...,
    ROW_NUMBER() OVER (
      PARTITION BY <grouping_columns>
      ORDER BY (mir.minutes * 6000 + mir.seconds * 100 + mir.hundredths) ASC
    ) as rn
  FROM FilteredData
)
SELECT <columns>
FROM RankedResults
WHERE rn = 1;
```

Standard output columns (expected by `AbstractBestResult`):

- `swimmer_id`, `swimmer_name`, `swimmer_year_of_birth`, `gender_type_id`
- `event_type_id`, `event_type_code`, `pool_type_id`, `pool_type_code`
- `season_id`, `season_header_year`
- `meeting_individual_result_id`, `minutes`, `seconds`, `hundredths`, `total_hundredths`
- `meeting_id`, `meeting_date`, `meeting_name`
- `team_id`, `team_name`

### 2. Generate the Migration

```bash
cd /home/steve/Projects/goggles_db

# For a NEW view:
rails generate scenic:view <view_name>

# For UPDATING an existing view (creates a new version):
rails generate scenic:view <view_name> --update
```

This generates a migration in `db/migrate/` that calls `create_view` or `update_view`.

For updates, also create a new SQL file with the incremented version number (e.g. `_v04.sql` → `_v05.sql`).

### 3. Run the Migration

```bash
cd /home/steve/Projects/goggles_db
rails db:migrate RAILS_ENV=test
```

### 4. Create or Update the Model

Create `app/models/goggles_db/<view_name>.rb`:

```ruby
# frozen_string_literal: true

module GogglesDb
  # = <ViewName> (Scenic View model)
  #
  # Represents the database view '<table_name>'.
  # <description of what the view contains>
  #
  class <ViewName> < AbstractBestResult
    self.primary_key = :meeting_individual_result_id
    self.table_name = '<view_table_name>'
  end
end
```

Key points:

- Inherit from `AbstractBestResult` (provides `readonly?`, associations, scopes, `TimingManageable`)
- Set `self.primary_key` to the unique identifier column (typically `:meeting_individual_result_id`)
- Set `self.table_name` explicitly to match the view name in the DB
- No need for validations (read-only)
- Additional scopes can be added if needed beyond what `AbstractBestResult` provides

### 5. What `AbstractBestResult` Provides

The base class (`app/models/goggles_db/abstract_best_result.rb`) includes:

- `readonly?` → always `true`
- `TimingManageable` concern for timing formatting
- `belongs_to` associations: `swimmer`, `event_type`, `gender_type`, `pool_type`, `season`, `meeting`, `meeting_individual_result`, `team`
- `default_scope` with `includes(...)` for all associations
- Scopes: `for_gender`, `for_event_type`, `for_pool_type`, `for_season`, `for_team_id`, `for_team_and_season_ids`, `sort_by_time`, `sort_fastest_first`, `sort_by_time_desc`

### 6. Write Specs

Create `spec/models/goggles_db/<view_name>_spec.rb`:

```ruby
# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe <ViewName> do
    subject { described_class.first }

    it 'is a read-only model' do
      expect(subject).to be_readonly
    end

    describe 'associations' do
      it { is_expected.to belong_to(:swimmer) }
      it { is_expected.to belong_to(:event_type) }
      # ...
    end

    describe 'scopes' do
      describe '.for_gender' do
        # ...
      end
    end
  end
end
```

### 7. Run Specs

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/models/goggles_db/<view_name>_spec.rb
```

### 8. Propagate

After committing and pushing `goggles_db`, run `./update_engine.sh` + `rails db:migrate RAILS_ENV=test` in each consumer project. The view model is available immediately via the engine — no API endpoint needed for views (they're typically queried directly by `goggles_main`).

## Updating an Existing View

When updating a view's SQL:

1. Create a new versioned SQL file (e.g. `_v04.sql` → `_v05.sql`)
2. Generate an update migration: `rails generate scenic:view <name> --update`
3. The migration will reference the new version automatically
4. The model file typically doesn't need changes unless columns changed
5. Update specs if the output columns or behavior changed
