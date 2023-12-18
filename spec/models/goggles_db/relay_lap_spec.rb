# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_lap_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe RelayLap do
    shared_examples_for 'a valid Lap instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[swimmer team
           parent_meeting meeting meeting_program
           meeting_relay_result meeting_relay_swimmer
           event_type category_type gender_type pool_type]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[length_in_meters minutes seconds hundredths]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[reaction_time stroke_cycles breath_cycles position
           parent_result meeting_relay_swimmer
           parent_result_id meeting_relay_swimmer_id
           minutes_from_start seconds_from_start hundredths_from_start
           timing_from_start
           meeting_attributes
           to_timing to_json]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:fixture_row) { FactoryBot.create(:relay_lap) }

    # No pre-seeded rows for this recent model. We'll use the factory anyway here
    # as 'existing_row' is still needed by the shared examples below.
    let(:existing_row) do
      list = FactoryBot.create_list(:relay_lap, 5, meeting_relay_swimmer: GogglesDb::MeetingRelaySwimmer.last(200).sample)
      list.sample
    end
    #-- ------------------------------------------------------------------------
    #++

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:relay_lap) }

      it_behaves_like('a valid Lap instance')
    end

    describe 'Misc scopes' do
      before { expect(existing_row).to be_valid }

      # Sorting scopes:
      it_behaves_like('AbstractLap sorting scopes', described_class)

      # Filtering scopes:
      it_behaves_like('AbstractLap filtering scopes', described_class)
    end

    # TimingManageable:
    describe 'regarding the timing fields,' do
      before { expect(fixture_row).to be_valid }

      # subject = fixture_row (can even be just built, not created)
      it_behaves_like('TimingManageable')
    end

    describe '#timing_from_start' do
      # Create some fixtures needed by this test:
      before do
        FactoryBot.create_list(:relay_lap, 3, meeting_relay_swimmer: GogglesDb::MeetingRelaySwimmer.last(200).sample)
        FactoryBot.create_list(
          :relay_lap, 3,
          hundredths_from_start: 0,
          seconds_from_start: 0,
          minutes_from_start: 0
        )
      end

      it_behaves_like('AbstractLap #timing_from_start', described_class)
    end

    it_behaves_like('AbstractLap #minimal_attributes', described_class)
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_hash' do
      subject { FactoryBot.create(:relay_lap) }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[gender_type team meeting_relay_result meeting_relay_swimmer event_type category_type]
      )

      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[meeting swimmer]
      )
    end
  end
end
