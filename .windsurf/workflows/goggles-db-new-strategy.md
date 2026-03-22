---
description: Add a strategy (calculator, db_finder, normalizer, timing_finder) under the GogglesDb namespace in goggles_db
auto_execution_mode: 2
---

# New Strategy in goggles_db

Use this skill when adding a new strategy class under the `GogglesDb::` namespace. Strategies are organized into families (calculators, db_finders, normalizers, timing_finders) and typically follow a base class + factory pattern.

## Background

- Strategies live in `/home/steve/Projects/goggles_db/app/strategies/goggles_db/`
- Four strategy families exist, plus standalone strategies
- Most families use a **BaseStrategy + Factory + concrete siblings** pattern

## Strategy Families

### Calculators (`calculators/`)

Score calculators for different federation types.

| File | Purpose |
| --- | --- |
| `base_strategy.rb` | Base interface for score calculation |
| `factory.rb` | Creates the right calculator from a `SeasonType` |
| `fin_score.rb` | FIN championship scoring |
| `csi_score.rb` | CSI championship scoring |
| `uisp_score.rb` | UISP championship scoring |

### DbFinders (`db_finders/`)

Fuzzy-search finders for entities using Jaro-Winkler distance.

| File | Purpose |
| --- | --- |
| `base_strategy.rb` | Base fuzzy-search logic (domain scan, weight computation, match collection) |
| `factory.rb` | Creates the right finder for a given model class |
| `fuzzy_swimmer.rb` | Swimmer search by `complete_name` + `year_of_birth` |
| `fuzzy_team.rb` | Team search by `editable_name` + `city_id` |
| `fuzzy_pool.rb` | SwimmingPool search by `name`/`nick_name` |
| `fuzzy_meeting.rb` | Meeting search by `description` |
| `fuzzy_city.rb` | City search by `name` + `country_code` |

### Normalizers (`normalizers/`)

Text normalization for entity names.

| File | Purpose |
| --- | --- |
| `city_name.rb` | Normalizes city names (accents, abbreviations) |
| `coded_name.rb` | Creates coded/canonical versions of names |

### TimingFinders (`timing_finders/`)

Find timing references for swimmers/events.

| File | Purpose |
| --- | --- |
| `base_strategy.rb` | Base interface for timing lookups |
| `factory.rb` | Creates the right finder from an `EntryTimeType` |
| `best_mir_for_event.rb` | Best MIR time for a specific event |
| `best_mir_for_meeting.rb` | Best MIR time for a meeting |
| `goggle_cup_for_event.rb` | GoggleCup standard time |
| `last_mir_for_event.rb` | Most recent MIR time |
| `no_time_for_event.rb` | Null-object (no time available) |

### Standalone Strategies

| File | Purpose |
| --- | --- |
| `grant_checker.rb` | Checks `AdminGrant` permissions for a user + entity |
| `manager_checker.rb` | Checks if a user manages a `TeamAffiliation` |
| `jwt_manager.rb` | JWT token creation/validation |
| `iso_region_list.rb` | ISO region/country lookups |

## Creating a Strategy in an Existing Family

### 1. Create the Strategy File

Example for a new `DbFinder`:

```ruby
# frozen_string_literal: true

require 'fuzzystringmatch'

module GogglesDb
  module DbFinders
    #
    # = GogglesDb::DbFinders::Fuzzy<Entity>
    #
    #   - version:  7-0.x.xx
    #   - author:   Steve A.
    #
    class Fuzzy<Entity> < BaseStrategy
      # Creates a new fuzzy finder for <Entity>.
      #
      # == Params:
      # - <tt>search_terms</tt>: Hash with column => value pairs
      # - <tt>bias</tt>: match threshold (default: DEFAULT_MATCH_BIAS)
      #
      def initialize(search_terms = {}, bias = DEFAULT_MATCH_BIAS)
        super(GogglesDb::<Entity>, search_terms, :for_name, bias)
      end

      # Scans the domain and returns the best match.
      # Call this, then check #matches for all candidates.
      def scan_for_matches
        # Optional: override to add custom pre-filtering or domain narrowing
        super
      end
    end
  end
end
```

### 2. Register in Factory (if applicable)

Edit the family's `factory.rb` to include the new strategy:

```ruby
# In db_finders/factory.rb:
def self.for(model_klass, search_terms, bias = BaseStrategy::DEFAULT_MATCH_BIAS)
  case model_klass.name
  when 'GogglesDb::<Entity>'
    Fuzzy<Entity>.new(search_terms, bias)
  # ... existing cases
  end
end
```

### 3. Write Specs

Create `spec/strategies/goggles_db/<family>/<strategy_name>_spec.rb`:

```ruby
# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe DbFinders::Fuzzy<Entity> do
    subject { described_class.new(search_terms) }

    let(:existing_row) { create(:<entity>) }
    let(:search_terms) { { target_column: existing_row.target_column } }

    describe '#scan_for_matches' do
      before { subject.scan_for_matches }

      it 'finds the expected row' do
        expect(subject.matches).not_to be_empty
        expect(subject.matches.first.candidate).to eq(existing_row)
      end
    end
  end
end
```

### 4. Run Tests

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/strategies/goggles_db/<family>/
```

## Creating a Standalone Strategy

For strategies that don't fit a family, create directly in `app/strategies/goggles_db/`:

```ruby
# frozen_string_literal: true

module GogglesDb
  #
  # = GogglesDb::<StrategyName>
  #
  class <StrategyName>
    def initialize(params)
      # ...
    end

    def call
      # Main logic
    end
  end
end
```

Place specs in `spec/strategies/goggles_db/<strategy_name>_spec.rb`.
