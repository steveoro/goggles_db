# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_lap_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe UserLap do
    # Make sure UserLaps have some permanent fixtures:
    # (These are supposed to remain there, and this is why an "after(:all)" clearing block
    # is totally missing here)
    before(:all) do
      if (GogglesDb::UserWorkshop.count < 10) || (GogglesDb::UserResult.count < 40) ||
         (described_class.count < 80)
        FactoryBot.create_list(:user_result_with_laps, 4)
        # Create also some fixtures with the timing from start zeroed out:
        # (needed as part of the domain by some of the tests below)
        FactoryBot.create_list(
          :user_lap, 8,
          user_result: FactoryBot.create(:user_result),
          hundredths_from_start: 0,
          seconds_from_start: 0,
          minutes_from_start: 0
        )
      end
      expect(GogglesDb::UserWorkshop.count).to be_positive
      expect(GogglesDb::UserResult.count).to be_positive
      expect(described_class.count).to be_positive
    end

    shared_examples_for 'a valid UserLap instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[swimmer user_result
           parent_meeting user_workshop
           event_type pool_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[length_in_meters minutes seconds hundredths]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[reaction_time position
           parent_result user_result
           parent_result_id user_result_id
           minutes_from_start seconds_from_start hundredths_from_start
           timing_from_start
           user_workshop_attributes meeting_attributes
           to_timing to_json]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    #-- ------------------------------------------------------------------------
    #++

    # TimingManageable:
    let(:fixture_row) { FactoryBot.create(:user_lap) }
    # Filtering scopes:
    let(:existing_row) do
      described_class.joins(:user_result)
                     .includes(:user_result)
                     .first(10).sample
    end

    context 'any pre-seeded instance' do
      subject { described_class.first(20).sample }

      it_behaves_like('a valid UserLap instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user_lap) }

      it_behaves_like('a valid UserLap instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    it_behaves_like('AbstractLap sorting scopes', described_class)

    it_behaves_like('AbstractLap filtering scopes', described_class)

    describe 'regarding the timing fields,' do
      # subject = fixture_row (can even be just built, not created)
      it_behaves_like('TimingManageable')
    end

    it_behaves_like('AbstractLap #timing_from_start', described_class)
    it_behaves_like('AbstractLap #minimal_attributes', described_class)
    #-- ------------------------------------------------------------------------
    #++

    describe '#to_hash' do
      subject { FactoryBot.create(:user_lap) }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[user_result event_type pool_type]
      )
      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[user_workshop swimmer]
      )
    end
  end
end
