# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe CmdCloneMeetingStructure, type: :command do
    let(:meeting_source) { GogglesDb::Meeting.limit(200).sample }
    let(:season_dest) { FactoryBot.create(:season) }

    before do
      expect(meeting_source).to be_a(GogglesDb::Meeting).and be_valid
      expect(season_dest).to be_a(GogglesDb::Season).and be_valid
    end

    context 'when using valid parameters,' do
      describe '#call' do
        subject { described_class.call(meeting_source, actual_dest_season) }

        let(:actual_dest_season) { [season_dest, nil].sample }

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'is successful' do
          expect(subject).to be_successful
        end

        it 'has a blank #errors list' do
          expect(subject.errors).to be_blank
        end

        it 'has a valid Meeting #result' do
          expect(subject.result).to be_a(GogglesDb::Meeting).and be_valid
        end

        it 'creates the new Meeting for the actual destination season (depending on supplied parameter)' do
          if actual_dest_season.nil?
            expect(subject.result.season_id).to eq(meeting_source.season_id)
          else
            expect(subject.result.season_id).to eq(actual_dest_season.id)
          end
        end

        it 'creates the new Meeting with an increased edition number' do
          expect(subject.result.edition).to eq(meeting_source.edition + 1)
        end

        it 'creates the new Meeting with no encapsulated manifest body' do
          expect(subject.result.manifest_body).to be_nil
        end

        it 'creates the new Meeting with all the data-import flags cleared out' do
          %i[
            manifest startlist autofilled confirmed
            tweeted posted cancelled pb_acquired read_only
          ].each do |column_name|
            expect(subject.result.send(column_name)).to be false
          end
        end

        it 'creates the same number of sessions as the source Meeting' do
          expect(subject.result.meeting_sessions.count).to eq(meeting_source.meeting_sessions.count)
        end

        it 'clears the autofilled flag from all the created sessions' do
          expect(subject.result.meeting_sessions.map(&:autofilled)).to all(be false)
        end

        it 'sets the scheduled_date of all the created sessions to the new Meeting header_date' do
          expect(subject.result.meeting_sessions.map(&:scheduled_date)).to all eq(subject.result.header_date)
        end

        it 'creates the same number & types of events' do
          expect(
            subject.result.meeting_events.map { |me| me.event_type.code }
          ).to match_array(
            meeting_source.meeting_events.map { |me| me.event_type.code }
          )
        end

        it 'clears the autofilled flag from all the created events' do
          expect(subject.result.meeting_events.map(&:autofilled)).to all(be false)
        end

        # Quick'n'ugly MeetingProgram decorator to get a distinct text code
        def compose_coded_meeting_program(meeting_prg)
          "#{meeting_prg.event_type.code}-#{meeting_prg.gender_type.code}-#{meeting_prg.category_type.code}"
        end

        it 'creates the same number & types of programs' do
          # Extract result list of coded programs and compare it with source:
          expect(
            subject.result.meeting_programs.map { |mprg| compose_coded_meeting_program(mprg) }
          ).to match_array(
            meeting_source.meeting_programs.map { |mprg| compose_coded_meeting_program(mprg) }
          )
        end

        it 'clears the autofilled flag from all the created programs' do
          expect(subject.result.meeting_programs.map(&:autofilled)).to all(be false)
        end

        # The following should never happen, but alas... (Just to prevent future regressions)
        it 'does not clone any associated results' do
          expect(subject.result.meeting_individual_results.count).to be_zero
          expect(subject.result.meeting_relay_results.count).to be_zero
        end

        it 'does not clone any associated entries' do
          expect(subject.result.meeting_entries.count).to be_zero
        end

        it 'does not clone any associated reservations' do
          expect(subject.result.meeting_reservations.count).to be_zero
          expect(subject.result.meeting_event_reservations.count).to be_zero
          expect(subject.result.meeting_relay_reservations.count).to be_zero
        end

        it 'does not clone any associated team scores' do
          expect(subject.result.meeting_team_scores.count).to be_zero
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using invalid constructor parameters,' do
      describe '#call' do
        subject do
          described_class.call(GogglesDb::User.first(50).sample)
        end

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'fails' do
          expect(subject).to be_a_failure
        end

        it 'has a non-empty #errors list displaying a error message about constructor parameters' do
          expect(subject.errors).to be_present
          expect(subject.errors[:msg]).to eq(['Invalid constructor parameters'])
        end

        it 'has a nil #result' do
          expect(subject.result).to be_nil
        end
      end
    end
  end
end
