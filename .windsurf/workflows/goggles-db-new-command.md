---
description: Create a new SimpleCommand in goggles_db — pattern, testing, and API exposure
auto_execution_mode: 2
---

# New Command in goggles_db

Use this skill when creating a new `SimpleCommand` in the `goggles_db` engine. Commands encapsulate a single business operation with a consistent interface.

## Background

- Commands live in `/home/steve/Projects/goggles_db/app/commands/goggles_db/`
- They use the `simple_command` gem (`prepend SimpleCommand`)
- Naming convention: `CmdVerbNoun` (e.g. `CmdFindDbEntity`, `CmdCloneCategories`)
- 8 existing commands as reference

## Existing Commands

| Command | Purpose |
| --- | --- |
| `CmdFindDbEntity` | Fuzzy-find any supported entity (Swimmer, Team, Pool, Meeting, City) |
| `CmdCloneCategories` | Clone CategoryTypes from one season to another |
| `CmdCloneMeetingStructure` | Clone a Meeting's structure (sessions, events, programs) |
| `CmdCreateReservation` | Create meeting reservations for a swimmer |
| `CmdFindEntryTime` | Find the best entry time for a swimmer/event |
| `CmdFindIsoCity` | Find a city using ISO data |
| `CmdFindIsoCountry` | Find a country using ISO data |
| `CmdSelectScoreCalculator` | Select the right score calculator for a season type |

## Step-by-step Procedure

### 1. Create the Command File

Create `app/commands/goggles_db/cmd_<verb>_<noun>.rb`:

```ruby
# frozen_string_literal: true

require 'simple_command'

module GogglesDb
  #
  # = <Description>
  #
  #   - version:  7-0.x.xx
  #   - author:   Steve A.
  #   - build:    YYYYMMDD
  #
  # == Returns
  # - result: <what .result returns on success>
  #
  class Cmd<Verb><Noun>
    prepend SimpleCommand

    # Creates a new command instance.
    #
    # == Params
    # - <tt>param_name</tt>: description (*required*)
    #
    def initialize(param_name:)
      @param_name = param_name
    end

    # Executes the command. Called internally by SimpleCommand when
    # you invoke .call() on the class or .call() on an instance.
    #
    # Sets the internal result on success; adds errors on failure.
    #
    def call
      # Validate inputs:
      unless @param_name.present?
        errors.add(:base, 'Invalid parameter')
        return
      end

      # Business logic here...
      # Set @result for the return value:
      @result = compute_something
    end

    private

    def compute_something
      # ...
    end
  end
end
```

### 2. SimpleCommand Interface

The `simple_command` gem provides:

```ruby
# Class-level call (creates instance + runs):
cmd = GogglesDb::CmdVerbNoun.call(param_name: value)

# Check results:
cmd.success?    # => true/false
cmd.result      # => the return value (set by @result in #call)
cmd.errors      # => ActiveModel::Errors-like object

# Instance-level:
cmd = GogglesDb::CmdVerbNoun.new(param_name: value)
cmd.call
```

Key conventions:

- Use `errors.add(:base, 'message')` for validation failures
- Return early after adding errors (don't set `@result`)
- The `@result` instance variable is what `.result` returns
- Additional reader attributes (like `@matches` in `CmdFindDbEntity`) can be exposed with `attr_reader`

### 3. Write Specs

Create `spec/commands/goggles_db/cmd_<verb>_<noun>_spec.rb`:

```ruby
# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe Cmd<Verb><Noun>, type: :command do
    describe '#call' do
      context 'with valid parameters' do
        subject { described_class.call(param_name: valid_value) }

        it 'is successful' do
          expect(subject).to be_success
        end

        it 'returns expected result' do
          expect(subject.result).to be_a(ExpectedClass)
        end
      end

      context 'with invalid parameters' do
        subject { described_class.call(param_name: nil) }

        it 'fails' do
          expect(subject).not_to be_success
        end

        it 'reports errors' do
          expect(subject.errors[:base]).to be_present
        end
      end
    end
  end
end
```

### 4. Run Tests

```bash
cd /home/steve/Projects/goggles_db
bundle exec rspec spec/commands/goggles_db/cmd_<verb>_<noun>_spec.rb
```

### 5. Expose via API (if needed)

If the command should be callable via `goggles_api`, add an endpoint in `goggles_api` (see `/goggles-api-new-endpoint`). Typically wrapped in a `tools` or dedicated resource:

```ruby
# In goggles_api app/api/goggles/tools_api.rb (or a new file):
resource :tools do
  desc 'Run <command description>'
  params do
    requires :param_name, type: String, desc: 'description'
  end
  post :<action_name> do
    api_user = check_jwt_session
    cmd = GogglesDb::CmdVerbNoun.call(param_name: params['param_name'])
    error!(cmd.errors.full_messages.join(', '), 422) unless cmd.success?
    { msg: 'OK', result: cmd.result }
  end
end
```
