# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe MeetingTeamScore, type: :model do
    shared_examples_for 'a valid MeetingTeamScore instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[team team_affiliation meeting season]
      )

      # Presence of fields:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[rank sum_individual_points sum_relay_points sum_team_points
           meeting_points meeting_relay_points meeting_team_points
           season_points season_relay_points season_team_points]
      )
    end

    context 'any valid, pre-seeded instance' do
      subject { described_class.last(20).sample }

      it_behaves_like('a valid MeetingTeamScore instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_team_score) }

      it_behaves_like('a valid MeetingTeamScore instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    describe 'self.with_season_score' do
      let(:fixture_meeting) do
        # Create a list with 5 team scores, 1 zero + 4 positive:
        first_score = FactoryBot.create(:meeting_team_score, season_points: 0, season_relay_points: 0, season_team_points: 0)
        FactoryBot.create_list(
          :meeting_team_score, 4,
          meeting: first_score.meeting,
          season: first_score.season
        )
        first_score.meeting
      end
      let(:result) { fixture_meeting.meeting_team_scores.with_season_score }

      it 'is a relation containing only positive MeetingTeamScores' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
        expect(result.sum { |row| row.season_points + row.season_relay_points + row.season_team_points }).to be_positive
      end
    end

    describe 'self.for_team' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'team')
    end

    describe 'self.for_meeting' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'meeting')
    end
  end
end
