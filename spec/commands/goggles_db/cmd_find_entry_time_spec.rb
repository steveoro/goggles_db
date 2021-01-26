# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe CmdFindEntryTime, type: :command do
    let(:fixture_pool_type)  { GogglesDb::PoolType.all_eventable.sample }
    let(:fixture_event_type) do
      GogglesDb::EventsByPoolType.eventable.individuals
                                 .for_pool_type(fixture_pool_type)
                                 .event_length_between(50, 1500)
                                 .sample
                                 .event_type
    end
    let(:fixture_mir) do
      GogglesDb::MeetingIndividualResult.includes(:pool_type, :event_type)
                                        .joins(:pool_type, :event_type)
                                        .qualifications
                                        .where(
                                          'pool_types.id': fixture_pool_type.id,
                                          'event_types.id': fixture_event_type.id
                                        ).limit(500).sample
    end
    let(:fixture_swimmer) { fixture_mir.swimmer }
    let(:fixture_meeting) { fixture_mir.meeting }
    # Make sure domain is coherent with expected context:
    before(:each) do
      expect(fixture_pool_type).to be_a(GogglesDb::PoolType).and be_valid
      expect(fixture_event_type).to be_a(GogglesDb::EventType).and be_valid
      expect(fixture_mir).to be_a(GogglesDb::MeetingIndividualResult).and be_valid
      expect(fixture_meeting).to be_a(GogglesDb::Meeting).and be_valid
      expect(fixture_swimmer).to be_a(GogglesDb::Swimmer).and be_valid
    end

    context 'when using valid parameters with a swimmer having previous MIRs,' do
      EntryTimeType.all.each do |entry_time_type|
        describe "#call (EntryTimeType '#{entry_time_type.code}')" do
          subject { CmdFindEntryTime.call(fixture_swimmer, fixture_meeting, fixture_event_type, fixture_pool_type, entry_time_type) }

          it 'returns itself' do
            expect(subject).to be_a(CmdFindEntryTime)
          end
          it 'is successful' do
            expect(subject).to be_successful
          end
          it 'has a blank #errors list' do
            expect(subject.errors).to be_blank
          end
          it 'sets the #result member to a valid Timing instance' do
            if entry_time_type.manual?
              # Manual = no-time
              expect(subject.result).to be_a(Timing).and eq(Timing.new)
            else
              expect(subject.result).to be_a(Timing)
              expect(subject.result.to_hundredths).to be_positive
            end
          end
          it 'sets the #mir member to an associated MIR instance (when available)' do
            expect(subject.mir).to be_a(MeetingIndividualResult)
            if entry_time_type.manual?
              # Manual = no-time => empty MIR
              expect(subject.mir.to_timing).to eq(Timing.new)
            else
              expect(subject.mir.to_timing).to eq(subject.result)
            end
          end
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using valid parameters but for a swimmer with no MIRs (and no GoggleCup),' do
      let(:new_swimmer) { FactoryBot.build(:swimmer) }
      let(:new_meeting) { FactoryBot.build(:meeting) }
      before(:each) do
        expect(new_swimmer).to be_a(GogglesDb::Swimmer).and be_valid
        expect(new_meeting).to be_a(GogglesDb::Meeting).and be_valid
      end

      EntryTimeType.all.each do |entry_time_type|
        describe "#call (EntryTimeType '#{entry_time_type.code}')" do
          subject { CmdFindEntryTime.call(new_swimmer, new_meeting, fixture_event_type, fixture_pool_type, entry_time_type) }

          it 'returns itself' do
            expect(subject).to be_a(CmdFindEntryTime)
          end
          it 'is successful' do
            expect(subject).to be_successful
          end
          it 'has a blank #errors list' do
            expect(subject.errors).to be_blank
          end
          it 'sets #result to a new blank Timing instance' do
            expect(subject.result).to be_a(Timing).and eq(Timing.new)
          end
          it 'sets #mir to a new blank (zeroed-time) MIR' do
            expect(subject.mir).to be_a(MeetingIndividualResult)
            expect(subject.mir.to_timing).to eq(Timing.new)
          end
        end
      end
    end

    context 'when using invalid constructor parameters,' do
      describe '#call' do
        subject do
          option = [fixture_swimmer, fixture_event_type,
                    fixture_pool_type, EntryTimeType.all.sample]
          # Make a random item invalid for the constructor:
          # (The Meeting instance is not critical and is not checked)
          option[(rand * 10 % option.size).to_i] = nil
          CmdFindEntryTime.call(option[0], fixture_meeting, option[2], option[3], option[4])
        end

        it 'returns itself' do
          expect(subject).to be_a(CmdFindEntryTime)
        end
        it 'fails' do
          expect(subject).to be_a_failure
        end
        it 'has a non-empty #errors list displaying a error message about constructor parameters' do
          expect(subject.errors).to be_present
          expect(subject.errors[:msg]).to eq(['Invalid constructor parameters'])
        end
        it 'has a nil #result' do
          expect(subject.result).to be nil
        end
        it 'has a nil #mir' do
          expect(subject.mir).to be nil
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
