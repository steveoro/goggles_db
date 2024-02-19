# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_meeting_examples'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe UserWorkshop do
    subject { FactoryBot.create(:user_workshop) }

    # Make sure UserWorkshop have some permanent fixtures:
    # (These are supposed to remain there, and this is why an "after(:all)" clearing block
    # is totally missing here)
    before(:all) do
      if (described_class.count < 10) || (GogglesDb::UserResult.count < 40) ||
         (GogglesDb::UserLap.count < 80)
        FactoryBot.create_list(:workshop_with_results_and_laps, 5)
      end
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

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[code header_date header_year edition description]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[by_date by_season for_name not_cancelled not_expired]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[swimming_pool
           user_results pool_types event_types swimmers
           edition_label minimal_attributes expired?
           off_season? confirmed? cancelled?
           autofilled? read_only? pb_acquired?
           to_json]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid UserWorkshop instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user_workshop) }

      it_behaves_like('a valid UserWorkshop instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    it_behaves_like('AbstractMeeting sorting & filtering scopes', :user_workshop)

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

    describe 'self.for_user' do
      let(:chosen_filter) { described_class.includes(:user).joins(:user).select(:user_id).distinct.limit(20).sample }

      context 'given the chosen User has any UserWorkshops associated to it,' do
        let(:result) { described_class.for_user(chosen_filter).limit(10) }

        it 'is a relation containing only UserWorkshops attended or created by the same user' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)
          expect(
            result.all? { |workshop| workshop.user_id == chosen_filter.id }
          ).to be true
        end
      end
    end

    describe 'self.for_team' do
      let(:chosen_filter) { described_class.includes(:team).joins(:team).select(:team_id).distinct.limit(20).sample }

      context 'given the chosen Team has any UserWorkshops associated to it,' do
        let(:result) { described_class.for_team(chosen_filter).limit(10) }

        it 'is a relation containing only UserWorkshops attended by the specified Team' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to all be_a(described_class)
          expect(
            result.all? { |workshop| workshop.team_id == chosen_filter.id }
          ).to be true
        end
      end
    end

    describe 'self.for_swimmer' do
      let(:chosen_result) do
        GogglesDb::UserResult.includes(:swimmer, :user_workshop).joins(:swimmer, :user_workshop)
                             .last(100).sample
      end
      let(:chosen_filter) { chosen_result.swimmer }

      context 'given the chosen Swimmer has any UserWorkshops associated to it,' do
        let(:result) { described_class.for_swimmer(chosen_filter).limit(10) }

        it 'is a relation containing only UserWorkshops attended by the same swimmer' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result.count).to be_positive
          expect(result).to all be_a(described_class)
          expect(
            result.any? { |workshop| workshop.swimmers.pluck(:id).uniq.include?(chosen_filter.id) }
          ).to be true
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.swimmer_presence?' do
      let(:chosen_result) do
        GogglesDb::UserResult.includes(:swimmer, :user_workshop).joins(:swimmer, :user_workshop)
                             .last(100).sample
      end
      let(:chosen_workshop) { chosen_result.user_workshop }
      let(:chosen_swimmer) { chosen_result.swimmer }
      let(:fixture_swimmer) { FactoryBot.create(:swimmer) }

      context 'when the chosen workshop has any results or presence of the chosen swimmer,' do
        it 'returns true' do
          expect(described_class.swimmer_presence?(chosen_workshop, chosen_swimmer)).to be true
        end
      end

      context 'when the chosen workshop does NOT have any results or presence of the chosen swimmer,' do
        it 'returns false' do
          expect(described_class.swimmer_presence?(chosen_workshop, fixture_swimmer)).to be false
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    it_behaves_like('AbstractMeeting #edition_label', :user_workshop)
    it_behaves_like('AbstractMeeting #name_without_edition', :user_workshop)
    it_behaves_like('AbstractMeeting #name_with_edition', :user_workshop)
    it_behaves_like('AbstractMeeting #condensed_name', :user_workshop)
    it_behaves_like('AbstractMeeting #expired?', :user_workshop)

    it_behaves_like('AbstractMeeting #minimal_attributes', described_class)

    describe '#to_hash' do
      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[user team season season_type federation_type edition_type timing_type]
      )

      # Optional associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 optional association with',
        %w[swimming_pool]
      )
    end
  end
end
