# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe GogglesDb::SwimmerStat, type: :model do
    subject { described_class.new(fixture_swimmer) }

    let(:fixture_swimmer) { GogglesDb::Swimmer.first(200).sample }

    before do
      expect(fixture_swimmer).to be_a(GogglesDb::Swimmer).and be_valid
    end

    it 'is a SwimmerStat instance' do
      expect(subject).to be_a(described_class)
    end

    it_behaves_like(
      'responding to a list of methods',
      %i[swimmer sql result]
    )

    describe '#result' do
      it 'is an Hash' do
        expect(subject.result).to be_an(Hash)
      end

      it 'has the expected keys' do
        expect(subject.result.keys).to match_array(
          %w[meetings_count individual_count total_fin_points
             individual_minutes individual_seconds individual_hundredths
             individual_meters individual_disqualified_count max_fin_points_data
             min_fin_points_data irons_count teams_name_and_ids first_meeting_data
             last_meeting_data relays_count relay_minutes relay_seconds relay_hundredths
             relay_meters relay_disqualified_count current_teams current_categories
             max_fin_points min_fin_points teams first_meeting last_meeting]
        )
      end
    end
  end
end
