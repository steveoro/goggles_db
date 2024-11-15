# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

module GogglesDb
  RSpec.describe MeetingEventReservation do
    shared_examples_for 'a valid MeetingEventReservation instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_reservation meeting meeting_event badge team swimmer
           season season_type meeting_session event_type category_type gender_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[minutes seconds hundredths
           accepted?
           meeting_attributes]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    context 'any pre-seeded instance' do
      subject { described_class.limit(20).sample }

      it_behaves_like('a valid MeetingEventReservation instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_event_reservation) }

      it_behaves_like('a valid MeetingEventReservation instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    describe 'self.accepted' do
      let(:result) { subject.class.where(accepted: true).limit(20) }

      it 'contains only accepted reservations' do
        expect(result).to all(be_accepted)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'regarding the timing fields,' do
      let(:fixture_row) { FactoryBot.build(:meeting_event_reservation) }

      it_behaves_like 'TimingManageable'
    end

    describe '#minimal_attributes (override)' do
      subject(:result) { fixture_row.minimal_attributes }

      let(:fixture_row) { described_class.limit(20).sample }

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
        end
      end

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

      it 'includes the category code & label' do
        expect(result['category_code']).to eq(fixture_row.category_type.code)
        expect(result['category_label']).to eq(fixture_row.category_type.decorate.short_label)
      end

      it 'includes the gender code' do
        expect(result['gender_code']).to eq(fixture_row.gender_type.code)
      end
    end

    describe '#to_hash' do
      subject { described_class.limit(20).sample }

      # Required associations:
      it_behaves_like(
        '#to_hash when the entity has any 1:1 required association with',
        %w[meeting_event event_type badge team swimmer]
      )
      it_behaves_like(
        '#to_hash when the entity has any 1:1 summarized association with',
        %w[meeting]
      )
    end
  end
end
