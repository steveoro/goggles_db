# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe CmdCloneMeetingStructure, type: :command do
    let(:meeting_source) { GogglesDb::Meeting.limit(200).sample }
    before(:each) do
      expect(meeting_source).to be_a(GogglesDb::Meeting).and be_valid
    end

    context 'when using valid parameters,' do
      describe '#call' do
        subject { CmdCloneMeetingStructure.call(meeting_source) }

        it 'returns itself' do
          expect(subject).to be_a(CmdCloneMeetingStructure)
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
        it 'creates the new Meeting with an increased edition number' do
          expect(subject.result.edition).to eq(meeting_source.edition + 1)
        end
        it 'creates the new Meeting with no encapsulated manifest body' do
          expect(subject.result.manifest_body).to be nil
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
          ).to eq(
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
          ).to eq(
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
  end
end
