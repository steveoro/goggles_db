---
description: Annual task — creating a new Season, its CategoryTypes, and all associated lookup rows
auto_execution_mode: 2
---

# Season Setup

Use this skill for the annual task of creating a new competition season with its associated lookup data. This typically happens once per year per federation type.

## Background

- Seasons are stored in `GogglesDb::Season` (in `goggles_db`)
- Each season has many `CategoryType` rows defining age groups
- Seasons link to a `SeasonType` (e.g. `MASFIN`, `MASCSI`) which links to a `FederationType`
- The `CmdCloneCategories` command can copy CategoryTypes from one season to the next

## Key Models

- **Season** — `begin_date`, `end_date`, `description`, `header_year` (e.g. "2025/2026"), `edition`, `season_type_id`, `edition_type_id`
- **SeasonType** — lookup: `MASFIN` (FIN Masters), `MASCSI` (CSI Masters), etc.
- **CategoryType** — age group per season: `code` (e.g. "M25"), `age_begin`, `age_end`, `season_id`, `group_name`, `short_name`, `federation_code`
- **FederationType** — lookup: FIN, CSI, UISP, LEN, FINA

## Step-by-step Procedure

### 1. Find the Previous Season

```ruby
# In goggles_db rails console:
prev_season = GogglesDb::Season.for_season_type(GogglesDb::SeasonType.mas_fin)
                               .by_begin_date.last
# => the most recent FIN Masters season
```

### 2. Create the New Season

```ruby
new_season = GogglesDb::Season.create!(
  description: "Circuito Italiano Master FIN #{new_year}/#{new_year + 1}",
  begin_date: Date.new(new_year, 9, 1),   # Typically starts in September
  end_date: Date.new(new_year + 1, 7, 31), # Ends in July
  header_year: "#{new_year}/#{new_year + 1}",
  edition: prev_season.edition + 1,
  season_type_id: prev_season.season_type_id,
  edition_type_id: prev_season.edition_type_id
)
```

Or via a migration in `goggles_db/db/migrate/` for a permanent, replayable record (check existing `data_fix_add_missing_seasons` migrations for the pattern).

### 3. Clone CategoryTypes

Use the existing command:

```ruby
cmd = GogglesDb::CmdCloneCategories.call(prev_season, new_season)
if cmd.success?
  puts "Created #{cmd.result.count} categories for season #{new_season.id}"
else
  puts cmd.errors.full_messages
end
```

This copies all CategoryType rows from the previous season, updating only the `season_id`.

### 4. Adjust Categories (if needed)

If the federation changed age group boundaries or added/removed categories:

```ruby
# Find and update specific categories:
cat = GogglesDb::CategoryType.for_season(new_season).find_by(code: 'M25')
cat.update!(age_begin: 25, age_end: 29)

# Or create a new one:
GogglesDb::CategoryType.create!(
  season_id: new_season.id,
  code: 'M20',
  federation_code: '3',
  description: 'Master 20',
  short_name: 'M 20',
  group_name: 'MASTER 20',
  age_begin: 20,
  age_end: 24,
  relay: false,
  out_of_race: false,
  undivided: false
)
```

### 5. Verify

```ruby
# Check category count matches expectations:
GogglesDb::CategoryType.for_season(new_season).count
# Typically ~20-30 categories per season

# Check individual categories:
GogglesDb::CategoryType.for_season(new_season).individuals.order(:age_begin).each do |cat|
  puts "#{cat.code}: #{cat.age_begin}-#{cat.age_end}"
end
```

### 6. Create as a Migration (recommended)

For traceability, create a data-fix migration in `goggles_db`:

```bash
cd /home/steve/Projects/goggles_db
rails generate migration DataFixAddSeason<Year>
```

Edit the migration to include all the steps above. See existing examples:

- `db/migrate/20210614074635_data_fix_add_missing_seasons.rb`
- `db/migrate/20220808114135_data_fix_add_next_seasons.rb`
- `db/migrate/20220808120347_data_fix_add_next_category_types.rb`

### 7. Propagate

After committing the migration:

1. Push `goggles_db`
2. Run `./update_engine.sh` + `rails db:migrate RAILS_ENV=test` in each consumer
3. The new season and categories will be available immediately

## Calendar Population

After the season is created, the `Calendar` rows are typically populated by the `goggles_admin2` import pipeline as meetings are crawled. No manual calendar setup is needed — the crawler and import pipeline handle this.

## Standard Timings (optional)

If the federation publishes updated standard timing tables for the new season, these go into `GogglesDb::StandardTiming` rows. These are used by calculators to compute scores. Import them via a data-fix migration or through the admin interface.
