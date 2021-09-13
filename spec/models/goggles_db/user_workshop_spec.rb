# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'
require 'support/shared_abstract_meeting_examples'

module GogglesDb
  RSpec.describe UserWorkshop, type: :model do
    # Make sure UserWorkshop have some fixtures too:
    #-- ------------------------------------------------------------------------
    #++

    subject { FactoryBot.create(:user_workshop) }

    before(:all) do
      FactoryBot.create_list(:workshop_with_results_and_laps, 5)
      expect(described_class.count).to be_positive
      expect(GogglesDb::UserResult.count).to be_positive
      expect(GogglesDb::UserLap.count).to be_positive
    end

    shared_examples_for 'a valid UserWorkshop instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[user team home_team season season_type federation_type edition_type timing_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[code header_date header_year edition description]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[by_date by_season for_name]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[swimming_pool pool_types event_types
           edition_label minimal_attributes
           off_season? confirmed? cancelled?
           autofilled? read_only? pb_acquired?
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid UserWorkshop instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user_workshop) }

      it_behaves_like('a valid UserWorkshop instance')
    end

    # Sorting scopes:
    describe 'self.by_date' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'date', 'header_date')
    end

    describe 'self.by_season' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'begin_date')
    end

    # Filtering scopes:
    describe 'self.for_name' do
      context 'when combined with other associations that include same-named columns,' do
        subject { described_class.for_name('workshop-') }

        it 'does not raise errors' do
          expect { subject.count }.not_to raise_error
        end
      end

      it_behaves_like('filtering scope FULLTEXT for_...', described_class, :for_name, %w[description code], 'workshop-')
    end
    #-- ------------------------------------------------------------------------
    #++

    it_behaves_like('AbstractMeeting #edition_label', :user_workshop)
    it_behaves_like('AbstractMeeting #minimal_attributes', described_class)

    describe '#to_json' do
      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[user home_team season edition_type timing_type season_type federation_type]
      )
    end
  end
end
