# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingRelayReservation, type: :model do
    shared_examples_for 'a valid MeetingRelayReservation instance' do
      it 'is valid' do
        expect(subject).to be_a(MeetingRelayReservation).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting meeting_event badge team swimmer user
           season season_type meeting_session event_type category_type gender_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[notes accepted? to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { MeetingRelayReservation.all.limit(20).sample }
      it_behaves_like('a valid MeetingRelayReservation instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_relay_reservation) }
      it_behaves_like('a valid MeetingRelayReservation instance')
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

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_relay_reservation) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_event event_type category_type gender_type badge team swimmer user]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting]
      )
    end
  end
end
