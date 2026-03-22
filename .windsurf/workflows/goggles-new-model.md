---
description: Add a new database table and model to goggles_db — migration, model, factory, decorator, specs, and propagation
auto_execution_mode: 2
---

# New Model in goggles_db

Use this skill when adding a new database table and its corresponding model to the `goggles_db` engine. After adding the model, you'll need to propagate the change to consumer projects.

## Step-by-step Procedure

### 1. Generate Migration

```bash
cd /home/steve/Projects/goggles_db
rails generate migration CreateGogglesDb<ModelName>s <column>:<type> ...
```

Edit the generated migration in `db/migrate/`. Follow existing conventions:

- Use `charset: "utf8mb3", collation: "utf8mb3_general_ci"` for standard tables (or `latin1` for system tables)
- Include `lock_version` (integer, default: 0) for optimistic locking
- Add appropriate indexes (especially for foreign keys and unique constraints)
- Add FULLTEXT indexes for searchable text columns

Example:

```ruby
class CreateGogglesDbExampleEntities < ActiveRecord::Migration[6.1]
  def change
    create_table :example_entities, charset: "utf8mb3", collation: "utf8mb3_general_ci" do |t|
      t.integer :lock_version, default: 0
      t.references :season, null: false, foreign_key: true
      t.string :code, limit: 20, null: false
      t.string :description, limit: 100
      t.timestamps
    end
    add_index :example_entities, [:season_id, :code], unique: true
  end
end
```

### 2. Run Migration

```bash
cd /home/steve/Projects/goggles_db
rails db:migrate RAILS_ENV=test
```

Verify the schema updated at `spec/dummy/db/schema.rb`.

### 3. Create the Model

Create `app/models/goggles_db/<model_name>.rb`. Follow existing patterns:

```ruby
# frozen_string_literal: true

module GogglesDb
  #
  # = GogglesDb::<ModelName>
  #
  #   - version:  7-0.x.xx
  #   - author:   Steve A.
  #
  class <ModelName> < ApplicationRecord
    self.table_name = '<table_name>'

    belongs_to :<parent_entity>
    validates_associated :<parent_entity>

    has_many :<children>, dependent: :delete_all

    validates :code, presence: true, uniqueness: { scope: :season_id }
    validates :description, length: { maximum: 100 }

    # Filtering scopes:
    scope :for_season, ->(season) { where(season_id: season.id) }
    scope :for_code,   ->(code)   { where(code: code) }

    # Override: returns the list of single association names
    # included by #to_hash / #to_json.
    def single_associations
      %w[<parent_entity>]
    end

    # Override: returns the list of multiple association names
    # included by #to_hash / #to_json.
    def multiple_associations
      %w[]
    end

    # Override: include decorated fields in the output.
    def minimal_attributes(locale = I18n.locale)
      super.merge(
        'display_label' => decorate.display_label(locale),
        'short_label' => decorate.short_label
      )
    end
  end
end
```

Key conventions:

- Always set `self.table_name` explicitly
- Use `validates_associated` for `belongs_to` associations
- Use `dependent: :delete_all` for `has_many` (faster than `:destroy`)
- Include `default_scope { includes(:lookup_type) }` for lookup type associations
- Override `single_associations` and `multiple_associations` for JSON serialization
- Override `minimal_attributes` for decorator fields in JSON output

### 4. Create the Factory

Create `spec/factories/goggles_db/<table_name>.rb`:

```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :<model_name>, class: 'GogglesDb::<ModelName>' do
    association :<parent_entity>
    code  { "#{FFaker::Lorem.characters(3)}#{(rand * 100).to_i}" }
    description { FFaker::Lorem.sentence[0..99] }
  end
end
```

Conventions:

- Use `FFaker` for random data (not `Faker`)
- Use `association` for `belongs_to` references
- Keep values realistic and within validation limits

### 5. Create a Decorator (if needed)

Create `app/decorators/goggles_db/<model_name>_decorator.rb`:

```ruby
# frozen_string_literal: true

module GogglesDb
  # = GogglesDb::<ModelName>Decorator
  class <ModelName>Decorator < Draper::Decorator
    delegate_all

    # Returns the display label for this instance.
    def display_label(locale = I18n.locale)
      # ...
    end

    # Returns a short label for select dropdowns.
    def short_label
      # ...
    end
  end
end
```

### 6. Write Model Specs

Create `spec/models/goggles_db/<model_name>_spec.rb`:

```ruby
# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe <ModelName> do
    subject { create(:<model_name>) }

    it 'is valid' do
      expect(subject).to be_valid
    end

    # Test associations:
    it_behaves_like('having one', :<parent_entity>)

    # Test validations:
    describe 'validations' do
      it { is_expected.to validate_presence_of(:code) }
    end

    # Test scopes:
    describe '.for_season' do
      # ...
    end
  end
end
```

### 7. Run Tests

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/models/goggles_db/<model_name>_spec.rb
bundle exec rspec spec/factories/goggles_db/<table_name>_spec.rb  # if exists
```

### 8. Update Version (if structural change)

Edit `lib/goggles_db/version.rb`:

- Bump `PATCH` and `BUILD`
- Update `Version::DB` if this is a schema-level change

### 9. Commit and Push

```bash
cd /home/steve/Projects/goggles_db
git add -A
git commit -m "Add <ModelName> model"
git push origin master
```

### 10. Propagate to Consumer Projects

Follow the `/goggles-engine-update` skill:

1. Run `./update_engine.sh` in each consumer
2. Run `rails db:migrate RAILS_ENV=test`
3. Add API endpoint in `goggles_api` if needed (see `/goggles-api-new-endpoint`)
4. Add views/components in `goggles_main` or `goggles_admin2` as needed

## Lookup Type vs Regular Model

If the new model is a **lookup/type table** (read-only reference data like `GenderType`, `EventType`):

- Inherit from `AbstractLookupEntity` instead of `ApplicationRecord`
- Include seed data in the migration or a data-fix migration
- No need for a POST/PUT API endpoint (lookup types are read-only)
- Use the `LookupAPI` pattern in `goggles_api` for listing
