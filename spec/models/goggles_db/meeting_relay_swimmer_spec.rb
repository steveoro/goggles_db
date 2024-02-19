# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe MeetingRelaySwimmer do
    shared_examples_for 'a valid MeetingRelaySwimmer instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      # Tests the validity of the default_scope when there's an optional association involved:
      it 'does not raise errors when selecting a random row with a field name' do
        %w[relay_order stroke_type_id].each do |field_name|
          expect { described_class.unscoped.select(field_name).limit(100).sample }.not_to raise_error
        end
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_relay_result swimmer badge stroke_type
           meeting meeting_session meeting_event meeting_program event_type team]
      )

      # Presence of fields & requirements:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[relay_order reaction_time]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[minutes seconds hundredths
           length_in_meters
           swimmer_attributes
           parent_result
           to_timing]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:fixture_row) { described_class.last(100).sample }

    context 'any pre-seeded instance' do
      subject { described_class.last(100).sample }

      it_behaves_like('a valid MeetingRelaySwimmer instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_relay_swimmer) }

      it_behaves_like('a valid MeetingRelaySwimmer instance')
    end

    # Sorting scopes:
    describe 'self.by_order' do
      let(:result) { described_class.limit(100).by_order }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'relay_order')
    end

    # Filtering scopes:
    describe 'self.with_time' do
      it_behaves_like('filtering scope with_time', described_class)
    end

    describe 'self.with_no_time' do
      it_behaves_like('filtering scope with_no_time', described_class)
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'regarding the timing fields,' do
      before { expect(fixture_row).to be_valid }

      # subject = fixture_row (can even be just built, not created)
      it_behaves_like('TimingManageable')
    end

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      it 'includes the timing string' do
        expect(result['timing']).to eq(fixture_row.to_timing.to_s)
      end

      it 'includes the swimmer name & decorated label' do
        expect(result['swimmer_name']).to eq(fixture_row.swimmer.complete_name)
        expect(result['swimmer_label']).to eq(fixture_row.swimmer.decorate.display_label)
      end

      it 'includes the team name & decorated label' do
        expect(result['team_name']).to eq(fixture_row.team.editable_name)
        expect(result['team_label']).to eq(fixture_row.team.decorate.display_label)
      end

      it 'includes the event label' do
        expect(result['event_label']).to eq(fixture_row.event_type.label)
      end

      it 'includes the stroke code' do
        expect(result['stroke_code']).to eq(fixture_row.stroke_type.code)
      end

      it 'includes the gender code' do
        expect(result['gender_code']).to eq(fixture_row.gender_type.code)
      end
    end

    describe '#to_hash' do
      subject { fixture_row }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[meeting_relay_result team badge event_type stroke_type]
      )
      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[swimmer]
      )
    end
  end
end
