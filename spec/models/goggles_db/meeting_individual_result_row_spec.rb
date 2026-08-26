# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe MeetingIndividualResultRow do
    let(:source_mir) do
      MeetingIndividualResult.joins(:meeting, :swimmer, :team)
                             .includes(:laps)
                             .where('meeting_individual_results.rank > 0')
                             .joins(:laps).distinct
                             .first
    end
    let(:fixture_row) { described_class.find(source_mir.id) }

    describe 'the view' do
      it 'has one row per source MIR with an existing swimmer' do
        expect(described_class.count).to eq(MeetingIndividualResult.joins(:swimmer).count)
      end

      it 'excludes MIRs whose swimmer_id no longer references an existing swimmer' do
        missing_swimmer_id = Swimmer.maximum(:id) + 1
        source_mir.swimmer_id = missing_swimmer_id
        source_mir.save!(validate: false)

        expect(described_class.exists?(source_mir.id)).to be(false)
      end
    end

    describe 'an instance' do
      subject(:result_row) { fixture_row }

      it 'is read-only' do
        expect(result_row).to be_readonly
        expect { result_row.update!(rank: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it 'mirrors the scalar values of the source MIR' do
        expect(result_row.meeting_individual_result_id).to eq(source_mir.id)
        expect(result_row.rank).to eq(source_mir.rank)
        expect(result_row.to_timing).to eq(source_mir.to_timing)
        expect(result_row.total_hundredths).to eq(source_mir.to_timing.to_hundredths)
        expect(result_row.standard_points).to eq(source_mir.standard_points)
        expect(result_row.disqualified).to eq(source_mir.disqualified)
      end

      it 'mirrors the flattened hierarchy & display attributes of the source MIR' do
        expect(result_row.meeting_id).to eq(source_mir.meeting.id)
        expect(result_row.meeting_program_id).to eq(source_mir.meeting_program_id)
        expect(result_row.meeting_event_id).to eq(source_mir.meeting_program.meeting_event_id)
        expect(result_row.event_type_id).to eq(source_mir.event_type.id)
        expect(result_row.category_type_id).to eq(source_mir.category_type.id)
        expect(result_row.category_code).to eq(source_mir.category_type.code)
        expect(result_row.gender_type_id).to eq(source_mir.gender_type.id)
        expect(result_row.season_id).to eq(source_mir.season.id)
        expect(result_row.season_type_id).to eq(source_mir.season.season_type_id)
        expect(result_row.swimmer_complete_name).to eq(source_mir.swimmer.complete_name)
        expect(result_row.swimmer_year_of_birth).to eq(source_mir.swimmer.year_of_birth)
        expect(result_row.team_name).to eq(source_mir.team.name)
        expect(result_row.team_editable_name).to eq(source_mir.team.editable_name)
      end

      describe '#laps' do
        it 'returns a JsonRow for each source lap, sorted by length_in_meters' do
          expect(result_row.laps_count).to eq(source_mir.laps.count)
          expect(result_row.laps).to all(be_a(JsonRow))
          expect(result_row.laps.map(&:id)).to eq(source_mir.laps.by_distance.map(&:id))
          expect(result_row.laps.map(&:length_in_meters)).to eq(source_mir.laps.by_distance.map(&:length_in_meters))
        end

        it 'supports timing helpers on each decoded lap' do
          lap_row = result_row.laps.first
          source_lap = source_mir.laps.by_distance.first
          expect(lap_row.to_timing).to eq(source_lap.to_timing)
          expect(lap_row.timing_from_start).to eq(source_lap.to_timing(from_start: true))
        end

        it 'returns an empty array when the source MIR has no laps' do
          no_laps_row = described_class.where(laps_count: 0).first
          expect(no_laps_row.laps).to eq([])
        end
      end
    end

    describe 'scopes' do
      let(:meeting_id) { described_class.group(:meeting_id).count.max_by { |_id, count| count }.first }

      describe '.for_meeting' do
        it 'returns only the rows for the specified meeting' do
          expect(described_class.for_meeting(meeting_id).pluck(:meeting_id).uniq).to eq([meeting_id])
        end
      end

      describe '.by_meeting_order' do
        it 'sorts by session & event order first' do
          tuples = described_class.for_meeting(meeting_id).by_meeting_order
                                  .pluck(:session_order, :event_order)
          expect(tuples).to eq(tuples.sort)
        end
      end

      describe '.with_rank / .with_no_rank' do
        it 'partitions all rows of a meeting' do
          scoped = described_class.for_meeting(meeting_id)
          expect(scoped.with_rank.count + scoped.with_no_rank.count).to eq(scoped.count)
          expect(scoped.with_rank.where('`rank` = 0 OR total_hundredths = 0')).to be_empty
        end
      end
    end
  end
end
