# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'

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

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[event_order]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[standard_timing meeting_individual_results meeting_relay_results meeting_relay_swimmers
           meeting_entries laps
           relay? scheduled_date
           begin_time autofilled? out_of_race?]
      )

      it_behaves_like('ApplicationRecord shared interface')
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

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { described_class.last(100).sample }

      it 'includes the event label' do
        expect(result['event_label']).to eq(fixture_row.event_type.label)
      end

      it 'includes the category code & label' do
        expect(result['category_code']).to eq(fixture_row.category_type.code)
        expect(result['category_label']).to eq(fixture_row.category_type.decorate.short_label)
      end

      it 'includes the gender code' do
        expect(result['gender_code']).to eq(fixture_row.gender_type.code)
      end

      it 'includes the pool code' do
        expect(result['pool_code']).to eq(fixture_row.pool_type.code)
      end
    end

    describe '#to_hash' do
      # Required associations:
      context 'for required associations,' do
        subject { described_class.last(100).sample }

        it_behaves_like(
          '#to_hash when the entity has any 1:1 required association with',
          %w[pool_type event_type category_type gender_type stroke_type]
        )
      end

      # Collection associations:
      context 'for collection associations,' do
        context 'when the entity has MIRs,' do
          subject do
            mir = GogglesDb::MeetingIndividualResult.last(200).sample
            expect(mir.meeting_program).to be_a(described_class).and be_valid
            mir.meeting_program
          end

          let(:result) { subject.to_hash(max_siblings: 3) } # limit sibling rows

          it "doesn't contain the MRR list" do
            expect(result['meeting_relay_results']).to be_nil
          end

          it_behaves_like(
            '#to_hash when the entity has any 1:N collection association with',
            %w[meeting_individual_results]
          )
        end

        context 'when the entity has MRRs,' do
          subject do
            mrr = GogglesDb::MeetingRelayResult.limit(200).sample
            expect(mrr.meeting_program).to be_a(described_class).and be_valid
            mrr.meeting_program
          end

          let(:result) { subject.to_hash(max_siblings: 3) } # limit sibling rows

          it "doesn't contain the MIR list" do
            expect(result['meeting_individual_results']).to be_nil
          end

          it_behaves_like(
            '#to_hash when the entity has any 1:N collection association with',
            %w[meeting_relay_results]
          )
        end
      end
    end
  end
end
