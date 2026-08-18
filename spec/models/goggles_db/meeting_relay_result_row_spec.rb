# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe MeetingRelayResultRow do
    let(:source_mrr) do
      MeetingRelayResult.joins(:meeting, :team, :meeting_relay_swimmers)
                        .where('meeting_relay_results.rank > 0')
                        .distinct.first
    end
    let(:fixture_row) { described_class.find(source_mrr.id) }

    describe 'the view' do
      it 'has one row per source MRR' do
        expect(described_class.count).to eq(MeetingRelayResult.count)
      end
    end

    describe 'an instance' do
      subject(:result_row) { fixture_row }

      it 'is read-only' do
        expect(result_row).to be_readonly
        expect { result_row.update!(rank: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it 'mirrors the scalar values of the source MRR' do
        expect(result_row.meeting_relay_result_id).to eq(source_mrr.id)
        expect(result_row.rank).to eq(source_mrr.rank)
        expect(result_row.to_timing).to eq(source_mrr.to_timing)
        expect(result_row.total_hundredths).to eq(source_mrr.to_timing.to_hundredths)
        expect(result_row.relay_code).to eq(source_mrr.relay_code)
        expect(result_row.disqualified).to eq(source_mrr.disqualified)
      end

      it 'mirrors the flattened hierarchy & display attributes of the source MRR' do
        expect(result_row.meeting_id).to eq(source_mrr.meeting.id)
        expect(result_row.meeting_program_id).to eq(source_mrr.meeting_program_id)
        expect(result_row.meeting_event_id).to eq(source_mrr.meeting_program.meeting_event_id)
        expect(result_row.event_type_id).to eq(source_mrr.event_type.id)
        expect(result_row.category_type_id).to eq(source_mrr.category_type.id)
        expect(result_row.gender_type_id).to eq(source_mrr.gender_type.id)
        expect(result_row.season_id).to eq(source_mrr.season.id)
        expect(result_row.team_name).to eq(source_mrr.team.name)
      end

      describe '#relay_swimmers' do
        it 'returns a JsonRow for each source relay swimmer, sorted by relay_order' do
          expect(result_row.meeting_relay_swimmers_count).to eq(source_mrr.meeting_relay_swimmers.count)
          expect(result_row.relay_swimmers).to all(be_a(JsonRow))
          expect(result_row.relay_swimmers.map(&:id))
            .to eq(source_mrr.meeting_relay_swimmers.order(:relay_order).map(&:id))
          expect(result_row.relay_swimmers.map(&:swimmer_complete_name))
            .to eq(source_mrr.meeting_relay_swimmers.order(:relay_order).map { |mrs| mrs.swimmer&.complete_name })
        end

        it 'supports timing helpers on each decoded leg' do
          leg_row = result_row.relay_swimmers.first
          source_leg = source_mrr.meeting_relay_swimmers.order(:relay_order).first
          expect(leg_row.to_timing).to eq(source_leg.to_timing)
          expect(leg_row.timing_from_start).to eq(source_leg.to_timing(from_start: true))
        end
      end

      describe '#relay_laps' do
        let(:source_mrr_with_laps) { RelayLap.first.meeting_relay_result }
        let(:row_with_laps) { described_class.find(source_mrr_with_laps.id) }

        it 'returns a JsonRow for each source relay lap, grouped under its leg' do
          source_laps = source_mrr_with_laps.relay_laps.pluck(:id, :meeting_relay_swimmer_id)
          expect(row_with_laps.relay_laps.map(&:id).sort).to eq(source_laps.map(&:first).sort)
          source_ids_by_leg = source_laps.group_by(&:last).transform_values { |tuples| tuples.map(&:first).sort }
          row_with_laps.relay_swimmers.each do |leg|
            expect(leg.relay_laps.map(&:id).sort).to eq(source_ids_by_leg.fetch(leg.id, []))
          end
        end

        it 'returns an empty array when the source MRR has no relay laps' do
          expect(fixture_row.relay_laps).to eq([]) if source_mrr.relay_laps.empty?
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
    end
  end
end
