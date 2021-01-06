# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingEventReservation, type: :model do
    shared_examples_for 'a valid MeetingEventReservation instance' do
      it 'is valid' do
        expect(subject).to be_a(MeetingEventReservation).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_reservation meeting meeting_event badge team swimmer
           season season_type meeting_session event_type category_type gender_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[minutes seconds hundreds
           accepted?
           meeting_attributes
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { MeetingEventReservation.all.limit(20).sample }
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

    describe '#minimal_attributes' do
      subject { GogglesDb::MeetingEventReservation.limit(20).sample.minimal_attributes }
      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      %w[meeting_event].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_event_reservation) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_event event_type badge team swimmer]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting]
      )
    end
  end
end
