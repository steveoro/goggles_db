# DataImport FactoryBot Factories Summary

## Design Patterns

### Composite Key Handling

All factories correctly generate and link composite keys:

```ruby
# Parent generates base key
sequence(:import_key) do |n|
  program_key = "#{n}-100SL-M45-M"
  swimmer_key = "M|SWIMMER#{n}|1978|TEAM#{n}"
  "#{program_key}/#{swimmer_key}"
end

# Child derives key from parent
import_key { "#{parent_import_key}/#{length_in_meters}" }
```

### Transient Attributes

Nested factories use transient attributes for parent linking:

```ruby
factory :data_import_lap_with_parent do
  transient do
    parent_result { nil }
  end

  after(:build) do |lap, evaluator|
    if evaluator.parent_result
      lap.parent_import_key = evaluator.parent_result.import_key
      lap.import_key = "#{evaluator.parent_result.import_key}/#{lap.length_in_meters}"
      lap.phase_file_path = evaluator.parent_result.phase_file_path
    end
  end
end
```

### Nested Factories with after(:create)

Complex scenarios create full object graphs:

```ruby
factory :data_import_meeting_relay_result_complete do
  after(:create) do |created_instance, _evaluator|
    # Create 4 relay laps
    [50, 100, 150, 200].each do |length|
      FactoryBot.create(:data_import_relay_lap, ...)
    end
    
    # Create 4 relay swimmers
    (1..4).each do |order|
      FactoryBot.create(:data_import_meeting_relay_swimmer, ...)
    end
  end
end
```

---

---

---

## Usage Patterns

### Factory Usage Examples

```ruby
# Basic creation
mir = FactoryBot.create(:data_import_meeting_individual_result)

# With traits
mir = FactoryBot.create(:data_import_meeting_individual_result, :disqualified, :with_rank)

# With nested associations (creates parent + 2 laps)
mir = FactoryBot.create(:data_import_meeting_individual_result_with_laps)

# Manual association linking
mir = FactoryBot.create(:data_import_meeting_individual_result)
lap = FactoryBot.create(
  :data_import_lap,
  parent_import_key: mir.import_key,
  import_key: "#{mir.import_key}/50",
  phase_file_path: mir.phase_file_path
)

# Using transient attributes
lap = FactoryBot.create(:data_import_lap_with_parent, parent_result: mir)
```

### With Traits

```ruby
# Disqualified result with rank
mir = FactoryBot.create(
  :data_import_meeting_individual_result,
  :disqualified,
  :with_rank
)

# First fraction of relay
swimmer = FactoryBot.create(
  :data_import_meeting_relay_swimmer,
  :first_fraction
)
```

### Nested Associations

```ruby
# Create MIR with 2 laps automatically
mir = FactoryBot.create(:data_import_meeting_individual_result_with_laps)
expect(mir.data_import_laps.count).to eq(2)

# Create relay result with laps AND swimmers
mrr = FactoryBot.create(:data_import_meeting_relay_result_complete)
expect(mrr.data_import_relay_laps.count).to eq(4)
expect(mrr.data_import_meeting_relay_swimmers.count).to eq(4)
```

### Manual Linking

```ruby
# Create parent then child
mir = FactoryBot.create(:data_import_meeting_individual_result)

lap = FactoryBot.create(
  :data_import_lap,
  parent_import_key: mir.import_key,
  import_key: "#{mir.import_key}/50",
  phase_file_path: mir.phase_file_path
)

expect(mir.data_import_laps).to include(lap)
```

### Transient Parent

```ruby
# Use transient attribute for automatic linking
mir = FactoryBot.create(:data_import_meeting_individual_result)
lap = FactoryBot.create(:data_import_lap_with_parent, parent_result: mir)

# Keys are automatically generated correctly
expect(lap.parent_import_key).to eq(mir.import_key)
expect(lap.import_key).to start_with(mir.import_key)
```

---

## Future Enhancements (Optional)

### Trait Library
- `:fast_time` - Competitive timing
- `:slow_time` - Recreational timing
- `:world_record` - Exceptional timing
- `:with_relay_code` - Specific relay codes

### Realistic Data
- Use Faker for swimmer/team names
- Real pool names and addresses
- Plausible meeting dates

### Integration with Existing Data
- `:from_dump` - Uses existing DB records
- `:matching_category` - Finds appropriate category
- `:valid_season` - Links to current season
