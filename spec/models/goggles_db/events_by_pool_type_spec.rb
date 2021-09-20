# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe EventsByPoolType, type: :model do
    let(:full_cached_table) { described_class.all_individuals + described_class.all_relays }

    context 'any pre-seeded instance' do
      subject { full_cached_table.sample }

      it 'is valid' do
        expect(subject).to be_an(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[pool_type event_type stroke_type]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[length_in_meters relay? eventable? to_json]
      )

      describe '#eventable?' do
        context 'with an Event/Pool type combination valid for a MeetingEvent,' do
          it 'returns true' do
            eventable_row = described_class.all_eventable.sample
            expect(eventable_row).to be_eventable
          end
        end

        context 'with an Event/Pool type combination not valid for any MeetingEvent,' do
          it 'returns false ' do
            uneventable_row = (full_cached_table - described_class.all_eventable).sample
            expect(uneventable_row.nil? || !uneventable_row&.eventable?).to be true
          end
        end
      end

      describe '#to_json' do
        it_behaves_like(
          '#to_json when called on a valid instance',
          %w[pool_type event_type stroke_type]
        )
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_pool' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'pool_type', 'length_in_meters')
    end

    describe 'self.by_event' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'event_type', 'style_order')
    end

    # Filtering scopes:
    describe 'self.relays' do
      let(:result) { subject.class.relays }

      it 'contains only relay events' do
        expect(result).to all(be_relay)
      end
    end

    describe 'self.individuals' do
      let(:result) { subject.class.individuals }

      it 'contains only individual events' do
        expect(result.map(&:relay?)).to all(be false)
      end
    end

    describe 'self.eventable' do
      let(:result) { subject.class.eventable }

      it 'contains only eventable events' do
        expect(result).to all(be_eventable)
      end
    end

    describe 'self.for_pool_type' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'pool_type')
    end

    describe 'self.event_length_between' do
      context 'when given a valid range of lengths,' do
        let(:result) { subject.class.event_length_between(50, 100) }

        it 'returns non-empty Relation of EventsByPoolType' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).not_to be_empty
          expect(result).to all be_an(described_class)
        end

        describe 'the result set' do
          it 'contains only events mapped into the specified length range' do
            list_of_lengths = result.map(&:length_in_meters).uniq
            expect(list_of_lengths).to all(be_between(50, 100))
          end
        end
      end

      context 'when given an invalid range of lengths,' do
        let(:result) { subject.class.event_length_between(0, 23) }

        it 'returns an empty Relation' do
          expect(result).to be_a(ActiveRecord::Relation)
          expect(result).to be_empty
        end
      end
    end

    # Virtual scopes:
    describe 'self.all_eventable' do
      let(:result) { subject.class.all_eventable }

      it 'is an array of eventable EventsByPoolType' do
        expect(result).to be_an(Array)
        expect(result).to all(be_eventable)
      end
    end

    describe 'self.all_relays' do
      let(:result) { subject.class.all_relays }

      it 'is an array of relay-only EventsByPoolType' do
        expect(result).to be_an(Array)
        expect(result).to all(be_relay)
      end
    end

    describe 'self.all_individuals' do
      let(:result) { subject.class.all_individuals }

      it 'is an array of individual-only EventsByPoolType' do
        expect(result).to be_an(Array)
        result.each do |row|
          expect(row.relay?).to be false
        end
      end
    end
  end
end
