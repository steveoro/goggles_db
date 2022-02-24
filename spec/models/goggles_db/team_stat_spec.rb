# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe GogglesDb::TeamStat, type: :model do
    subject { described_class.new(fixture_team) }

    let(:fixture_team) { GogglesDb::Team.first(200).sample }

    before do
      expect(fixture_team).to be_a(GogglesDb::Team).and be_valid
    end

    it 'is a SwimmerStat instance' do
      expect(subject).to be_a(described_class)
    end

    it_behaves_like(
      'responding to a list of methods',
      %i[team sql results]
    )

    describe '#results' do
      it 'is an Array of Hash rows' do
        expect(subject.results).to be_an(Array)
        expect(subject.results).to all be_an(Hash)
      end

      it 'has the expected keys' do
        expect(subject.results.map(&:keys)).to all match_array(
          %w[federation_name first_meeting_data last_meeting_data
             affiliations_count meetings_count max_updated_at
             first_meeting last_meeting]
        )
      end
    end
  end
end
