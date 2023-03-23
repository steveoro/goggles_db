# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingProgram do
    shared_examples_for 'a valid MeetingProgram instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting meeting_session meeting_event
           pool_type event_type category_type gender_type stroke_type]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[event_order]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[standard_timing meeting_individual_results meeting_relay_results meeting_relay_swimmers
           meeting_entries laps
           relay? scheduled_date
           begin_time autofilled? out_of_race?
           minimal_attributes
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid MeetingProgram instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_program) }

      it_behaves_like('a valid MeetingProgram instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_event_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'event_type', 'code')
    end

    describe 'self.by_category_type' do
      it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'category_type', 'code')
    end

    # Filtering scopes:
    describe 'self.relays' do
      let(:result) { subject.class.relays.limit(20) }

      it 'contains only relay events' do
        expect(result).to all(be_relay)
      end
    end

    describe 'self.individuals' do
      let(:result) { subject.class.individuals.limit(20) }

      it 'contains only individual events' do
        expect(result.map(&:relay?)).to all(be false)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#minimal_attributes' do
      subject { described_class.limit(500).sample.minimal_attributes }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end

      %w[pool_type event_type category_type gender_type stroke_type].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      # Required associations:
      context 'for required associations,' do
        subject { FactoryBot.create(:meeting_program) }

        it_behaves_like(
          '#to_json when called on a valid instance',
          %w[meeting_event pool_type event_type category_type gender_type stroke_type]
        )
      end

      # Collection associations:
      context 'for collection associations,' do
        context 'when the entity has MIRs,' do
          subject do
            mir = GogglesDb::MeetingIndividualResult.limit(200).sample
            expect(mir.meeting_program).to be_a(described_class).and be_valid
            mir.meeting_program
          end

          let(:json_hash) { JSON.parse(subject.to_json) }

          it "doesn't contain the MRR list" do
            expect(json_hash['meeting_relay_results']).to be_nil
          end

          it_behaves_like(
            '#to_json when the entity contains collection associations with',
            %w[meeting_individual_results]
          )
        end

        context 'when the entity has MRRs,' do
          subject do
            mrr = GogglesDb::MeetingRelayResult.limit(200).sample
            expect(mrr.meeting_program).to be_a(described_class).and be_valid
            mrr.meeting_program
          end

          let(:json_hash) { JSON.parse(subject.to_json) }

          it "doesn't contain the MIR list" do
            expect(json_hash['meeting_individual_results']).to be_nil
          end

          it_behaves_like(
            '#to_json when the entity contains collection associations with',
            %w[meeting_relay_results]
          )
        end
      end
    end
  end
end
