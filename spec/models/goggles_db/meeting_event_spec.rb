# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingEvent, type: :model do
    shared_examples_for 'a valid MeetingEvent instance' do
      it 'is valid' do
        expect(subject).to be_a(MeetingEvent).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_session event_type heat_type
           season meeting season_type stroke_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[event_order]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[meeting_programs meeting_individual_results meeting_relay_results meeting_entries category_types
           begin_time notes autofilled? out_of_race? eventable?
           split_gender_start_list? split_category_start_list?
           scheduled_date relay?
           minimal_attributes
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { MeetingEvent.all.limit(20).sample }
      it_behaves_like('a valid MeetingEvent instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_event) }
      it_behaves_like('a valid MeetingEvent instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Prepare lists of both event types:
    let(:same_session_events) do
      meeting_session = FactoryBot.create(:meeting_session)
      FactoryBot.create_list(:meeting_event_individual, 3, meeting_session: meeting_session)
      FactoryBot.create_list(:meeting_event_relay, 3, meeting_session: meeting_session)
      meeting_session.meeting_events
    end
    subject { same_session_events.sample }

    # Sorting scopes:
    describe 'self.by_order' do
      it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', MeetingEvent, 'order', 'event_order')
    end

    # Filtering scopes:
    describe 'self.relays' do
      it 'contains only relay events' do
        expect(same_session_events.relays).to all(be_relay)
      end
    end
    describe 'self.individuals' do
      it 'contains only individual events' do
        expect(same_session_events.individuals.map(&:relay?)).to all(be false)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#eventable?' do
      context 'for an in-race event,' do
        subject { FactoryBot.create(:meeting_event, out_of_race: false) }
        it 'returns true' do
          expect(subject.eventable?).to be true
        end
      end
      context 'for an out-of-race event,' do
        subject { FactoryBot.create(:meeting_event, out_of_race: true) }
        it 'returns false' do
          expect(subject.eventable?).to be false
        end
      end
    end

    describe '#minimal_attributes' do
      subject { GogglesDb::MeetingEvent.limit(200).sample.minimal_attributes }
      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      %w[event_type stroke_type heat_type].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_session event_type stroke_type heat_type season season_type]
      )
      # Collection associations:
      context 'when the entity contains collection associations,' do
        subject do
          prg = GogglesDb::MeetingProgram.limit(200).sample
          expect(prg.meeting_event).to be_a(MeetingEvent).and be_valid
          prg.meeting_event
        end
        let(:json_hash) { JSON.parse(subject.to_json) }

        it_behaves_like(
          '#to_json when the entity contains collection associations with',
          %w[meeting_programs]
        )
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Verify that the "has_one :meeting, through: :meeting_session" association now relies on
    # a properly defined callback chain: (was yielding errors in previous versions)
    context 'when deleting a Meeting that is an ancestor of an existing event,' do
      subject { FactoryBot.create(:meeting_event) }
      it 'does not yield any error' do
        expect { subject.meeting.destroy }.not_to raise_error
      end
    end
  end
end
