# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingRelayReservation, type: :model do
    shared_examples_for 'a valid MeetingRelayReservation instance' do
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
        %i[notes accepted? meeting_attributes to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

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

    describe '#minimal_attributes' do
      subject { described_class.limit(20).sample.minimal_attributes }

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
      subject { FactoryBot.create(:meeting_relay_reservation) }

      let(:json_hash) { JSON.parse(subject.to_json) }

      # Required keys:
      %w[
        display_label short_label
        meeting meeting_event event_type badge team swimmer
      ].each do |member_name|
        it "includes the #{member_name} member key" do
          expect(json_hash[member_name]).to be_present
        end
      end

      %w[display_label short_label].each do |method_name|
        it "includes the decorated '#{method_name}'" do
          expect(json_hash[method_name]).to eq(subject.decorate.send(method_name))
        end
      end

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
