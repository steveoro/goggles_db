# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_timing_finders_examples'

module GogglesDb
  RSpec.describe TimingFinders::BestMIRForEvent, type: :strategy do
    it_behaves_like('responding to a list of methods', %i[search_by])

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
    #-- -----------------------------------------------------------------------
    #++

    describe '#search_by' do
      context 'when the parameters scope out existing MIRs,' do
        subject { TimingFinders::BestMIRForEvent.new.search_by(fixture_swimmer, fixture_meeting, fixture_event_type, fixture_pool_type) }

        it_behaves_like('a TimingFinder strategy #search_by that can select a MIR with a non-zero timing value')
      end

      context 'when the parameters do not relate to any of the existing MIRs,' do
        let(:new_swimmer) { FactoryBot.build(:swimmer) }
        let(:new_meeting) { FactoryBot.build(:meeting) }
        before(:each) do
          expect(new_swimmer).to be_a(GogglesDb::Swimmer).and be_valid
          expect(new_meeting).to be_a(GogglesDb::Meeting).and be_valid
        end

        subject { TimingFinders::BestMIRForEvent.new.search_by(new_swimmer, new_meeting, fixture_event_type, fixture_pool_type) }

        it_behaves_like('a TimingFinder strategy #search_by that cannot find any related MIR row')
      end
    end
  end
end
