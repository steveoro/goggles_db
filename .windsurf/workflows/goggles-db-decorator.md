---
description: Add or modify a Draper decorator in goggles_db — display labels, short labels, and consumer overrides
auto_execution_mode: 2
---

# Decorator in goggles_db

Use this skill when adding or modifying a Draper decorator in the `goggles_db` engine. Decorators provide display-oriented methods for models without polluting the model layer.

## Background

- Decorators live in `/home/steve/Projects/goggles_db/app/decorators/goggles_db/`
- 20 existing decorators, all following the same minimal pattern
- Consumer projects (`goggles_main`, `goggles_admin2`) can extend base decorators with their own in `app/decorators/`
- Models call `decorate` to get a decorated instance (e.g. in `minimal_attributes`)

## Existing Decorators

`BadgeDecorator`, `CalendarDecorator`, `CategoryTypeDecorator`, `CityDecorator`, `ImportQueueDecorator`, `IssueDecorator`, `ManagedAffiliationDecorator`, `MeetingDecorator`, `MeetingEventDecorator`, `MeetingEventReservationDecorator`, `MeetingRelayReservationDecorator`, `MeetingReservationDecorator`, `SeasonDecorator`, `StandardTimingDecorator`, `SwimmerDecorator`, `SwimmingPoolDecorator`, `TeamAffiliationDecorator`, `TeamDecorator`, `UserDecorator`, `UserWorkshopDecorator`

## The Standard Pattern

Every decorator follows this minimal structure:

```ruby
# frozen_string_literal: true

module GogglesDb
  # = <ModelName>Decorator
  #
  class <ModelName>Decorator < Draper::Decorator
    delegate_all

    # Label method for displaying the main data for the instance row.
    # Returns an unstyled string.
    # Supports current locale override.
    def display_label(locale_code = I18n.locale)
      # Return a human-readable string combining key attributes
      "#{primary_field} (#{secondary_field})"
    end

    # Alternative shorter label for dropdowns, compact views, etc.
    def short_label
      "#{primary_field} (#{compact_info})"
    end
  end
end
```

Real example (`SwimmerDecorator`):

```ruby
def display_label(locale_code = I18n.locale)
  "#{complete_name} (#{gender_type&.label(locale_code)}, #{year_of_birth}#{'~' if year_guessed})"
end

def short_label
  "#{complete_name} (#{year_of_birth}#{'~' if year_guessed})"
end
```

## Step-by-step Procedure

### 1. Create the Decorator

Create `app/decorators/goggles_db/<model_name>_decorator.rb` following the pattern above.

Key conventions:

- Always `delegate_all` — gives access to all model methods
- `display_label(locale_code)` — primary display method, supports locale
- `short_label` — compact version for Select2 dropdowns, tables, etc.
- Return plain strings (no HTML) — HTML is the consumer's responsibility
- Use `&.` safe navigation for optional associations

### 2. Wire the Model

In the model's `minimal_attributes` method, include decorated fields:

```ruby
def minimal_attributes(locale = I18n.locale)
  super.merge(
    'display_label' => decorate.display_label(locale),
    'short_label' => decorate.short_label
  )
end
```

This ensures the labels appear in JSON output (API responses, `to_hash`).

### 3. Write Specs

Create `spec/decorators/goggles_db/<model_name>_decorator_spec.rb`:

```ruby
# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe <ModelName>Decorator, type: :decorator do
    subject { described_class.new(model_instance) }

    let(:model_instance) { create(:<model_name>) }

    describe '#display_label' do
      it 'returns a non-empty string' do
        expect(subject.display_label).to be_a(String).and be_present
      end
    end

    describe '#short_label' do
      it 'returns a non-empty string' do
        expect(subject.short_label).to be_a(String).and be_present
      end
    end
  end
end
```

### 4. Run Tests

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/decorators/goggles_db/<model_name>_decorator_spec.rb
```

## Consumer Overrides

`goggles_main` (8 decorators) and `goggles_admin2` (2 decorators) can extend or override engine decorators:

```ruby
# In goggles_main/app/decorators/<model_name>_decorator.rb:
class <ModelName>Decorator < GogglesDb::<ModelName>Decorator
  # Add HTML-aware display methods for views:
  def linked_display_label
    h.link_to(display_label, h.swimmer_path(object))
  end
end
```

Consumer decorators live outside the `GogglesDb::` namespace and inherit from the engine's decorator class.
