# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_best_result_examples'

module GogglesDb
  RSpec.describe GogglesCup3yBaseTimings do
    context 'shared behaviors' do
      # Include shared examples for common AbstractBestResult behavior
      it_behaves_like('an AbstractBestResult descendant', described_class)

      # Include shared examples for scopes
      it_behaves_like('AbstractBestResult filtering scopes', described_class)
      it_behaves_like('AbstractBestResult sorting scopes', described_class)
    end

    describe '.with_base_year' do
      let(:event_type) { GogglesDb::EventType.find(11) }
      let(:gender_type) { GogglesDb::GenderType.male }
      let(:pool_type) { GogglesDb::PoolType.find(1) }

      def create_season_with_meeting(begin_date, end_date, season_type_id = 1)
        season = create(
          :season,
          season_type_id: season_type_id,
          begin_date: begin_date,
          end_date: end_date,
          header_year: "#{begin_date.year}/#{end_date.year}"
        )
        meeting = create(
          :meeting,
          season: season,
          header_date: begin_date + 90.days
        )
        create(:meeting_session, meeting: meeting, scheduled_date: meeting.header_date)
      end

      def create_result_in_session(meeting_session, swimmer: nil, team: nil, team_affiliation: nil, seconds: 33)
        program = create(
          :meeting_program,
          meeting_session: meeting_session,
          event_type: event_type,
          gender_type: gender_type,
          pool_type: pool_type
        )
        attrs = {
          meeting_program: program,
          minutes: 0,
          seconds: seconds,
          hundredths: 0,
          disqualified: false
        }
        attrs[:swimmer] = swimmer if swimmer
        attrs[:team] = team if team
        attrs[:team_affiliation] = team_affiliation if team_affiliation
        create(:meeting_individual_result, **attrs)
      end

      after { described_class.with_base_year.to_a }

      it 'selects the 3-year window ending at the provided base year' do
        _base_session = create_season_with_meeting(
          Date.new(3000, 9, 1), Date.new(3001, 6, 30)
        )
        previous_session = create_season_with_meeting(
          Date.new(2999, 9, 1), Date.new(3000, 6, 30), 8
        )
        base_mir = create_result_in_session(previous_session, seconds: 32)

        row = described_class.with_base_year(3000).where(
          swimmer_id: base_mir.swimmer_id,
          event_type_id: event_type.id,
          pool_type_id: pool_type.id
        ).first

        expect(row).not_to be_nil
        expect(row.season_id).to eq(previous_session.meeting.season.id)
      end

      it 'excludes results outside the 3-year window relative to the base year' do
        _base_session = create_season_with_meeting(
          Date.new(3000, 9, 1), Date.new(3001, 6, 30)
        )
        far_session = create_season_with_meeting(
          Date.new(2996, 9, 1), Date.new(2997, 6, 30), 8
        )
        base_mir = create_result_in_session(far_session, seconds: 32)

        rows = described_class.with_base_year(3000).where(
          swimmer_id: base_mir.swimmer_id,
          event_type_id: event_type.id,
          pool_type_id: pool_type.id
        )

        expect(rows).to be_empty
      end

      it 'sets and clears the @base_year session variable' do
        described_class.with_base_year(2020).to_a
        expect(described_class.connection.select_value('SELECT @base_year').to_i).to eq(2020)

        described_class.with_base_year.to_a
        expect(described_class.connection.select_value('SELECT @base_year')).to be_nil
      end
    end
  end
end
