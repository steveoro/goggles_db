# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_abstract_best_result_examples'

module GogglesDb
  RSpec.describe BestSwimmerCurrentVsPreviousResult do
    context 'shared behaviors' do
      it_behaves_like('an AbstractBestResult descendant', described_class)
      it_behaves_like('AbstractBestResult filtering scopes', described_class)
      it_behaves_like('AbstractBestResult sorting scopes', described_class)
    end

    describe 'old result columns' do
      let(:event_type) { GogglesDb::EventType.find(11) }
      let(:gender_type) { GogglesDb::GenderType.male }
      let(:pool_type) { GogglesDb::PoolType.find(1) }

      def create_current_meeting_session
        current_begin_date = Date.new(2999, 1, 1)
        current_end_date = Date.new(2999, 12, 31)
        current_season = create(
          :season,
          season_type_id: 1,
          begin_date: current_begin_date,
          end_date: current_end_date,
          header_year: "#{current_begin_date.year}/#{current_end_date.year}"
        )
        current_meeting = create(
          :meeting,
          season: current_season,
          header_date: current_begin_date + 90.days
        )
        create(:meeting_session, meeting: current_meeting, scheduled_date: current_meeting.header_date)
      end

      def create_previous_meeting_session
        previous_begin_date = Date.new(2998, 1, 1)
        previous_end_date = Date.new(2998, 12, 31)
        previous_season = create(
          :season,
          season_type_id: 8,
          begin_date: previous_begin_date,
          end_date: previous_end_date,
          header_year: "#{previous_begin_date.year}/#{previous_end_date.year}"
        )
        previous_meeting = create(
          :meeting,
          season: previous_season,
          header_date: previous_begin_date + 120.days
        )
        create(:meeting_session, meeting: previous_meeting, scheduled_date: previous_meeting.header_date)
      end

      it 'exposes old timing and meeting fields in the view schema' do
        expect(described_class.column_names).to include(
          'old_meeting_individual_result_id', 'old_meeting_id', 'old_meeting_date', 'old_meeting_name',
          'old_total_hundredths', 'old_minutes', 'old_seconds', 'old_hundredths'
        )
      end

      it 'keeps old payload coherent when old result is present' do # rubocop:disable RSpec/ExampleLength
        current_session = create_current_meeting_session
        current_program = create(
          :meeting_program,
          meeting_session: current_session,
          event_type: event_type,
          gender_type: gender_type,
          pool_type: pool_type
        )
        current_mir = create(
          :meeting_individual_result,
          meeting_program: current_program,
          minutes: 0,
          seconds: 33,
          hundredths: 95,
          disqualified: false
        )

        previous_session = create_previous_meeting_session
        previous_program = create(
          :meeting_program,
          meeting_session: previous_session,
          event_type: event_type,
          gender_type: gender_type,
          pool_type: pool_type
        )
        old_mir = create(
          :meeting_individual_result,
          meeting_program: previous_program,
          swimmer: current_mir.swimmer,
          team: current_mir.team,
          team_affiliation: current_mir.team_affiliation,
          minutes: 0,
          seconds: 34,
          hundredths: 14,
          disqualified: false
        )

        row = described_class.where(
          swimmer_id: current_mir.swimmer_id,
          event_type_id: event_type.id,
          pool_type_id: pool_type.id
        ).first

        expect(row).not_to be_nil

        expect(row.old_meeting_id).not_to be_nil
        expect(row.old_meeting_date).not_to be_nil
        expect(row.old_meeting_name).not_to be_nil
        expect(row.old_total_hundredths).not_to be_nil

        expected_old_total = (row.old_minutes.to_i * 6000) + (row.old_seconds.to_i * 100) + row.old_hundredths.to_i
        expect(row.old_total_hundredths.to_i).to eq(expected_old_total)

        old_result = GogglesDb::MeetingIndividualResult.find(row.old_meeting_individual_result_id)
        old_meeting = old_result.meeting_program.meeting_event.meeting_session.meeting

        expect(row.old_meeting_individual_result_id).to eq(old_mir.id)
        expect(old_result.minutes).to eq(row.old_minutes)
        expect(old_result.seconds).to eq(row.old_seconds)
        expect(old_result.hundredths).to eq(row.old_hundredths)
        expect(old_meeting.id).to eq(row.old_meeting_id)
        expect(old_meeting.header_date).to eq(row.old_meeting_date)
        expect(old_meeting.description).to eq(row.old_meeting_name)
      end

      it 'keeps all old payload fields nil when baseline is missing' do # rubocop:disable RSpec/ExampleLength
        current_session = create_current_meeting_session
        current_program = create(
          :meeting_program,
          meeting_session: current_session,
          event_type: event_type,
          gender_type: gender_type,
          pool_type: pool_type
        )
        current_mir = create(
          :meeting_individual_result,
          meeting_program: current_program,
          minutes: 0,
          seconds: 35,
          hundredths: 20,
          disqualified: false
        )

        row = described_class.where(
          swimmer_id: current_mir.swimmer_id,
          event_type_id: event_type.id,
          pool_type_id: pool_type.id
        ).first

        expect(row).not_to be_nil

        expect(row.old_meeting_id).to be_nil
        expect(row.old_meeting_date).to be_nil
        expect(row.old_meeting_name).to be_nil
        expect(row.old_total_hundredths).to be_nil
        expect(row.old_minutes).to be_nil
        expect(row.old_seconds).to be_nil
        expect(row.old_hundredths).to be_nil
      end
    end
  end
end
