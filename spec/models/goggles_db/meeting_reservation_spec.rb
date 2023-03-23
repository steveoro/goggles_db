# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingReservation do
    shared_examples_for 'a valid MeetingReservation instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting user team badge swimmer
           season season_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[meeting_event_reservations meeting_relay_reservations
           not_coming? confirmed? coming?
           minimal_attributes meeting_attributes
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { described_class.all.limit(20).sample }

      it_behaves_like('a valid MeetingReservation instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_reservation) }

      it_behaves_like('a valid MeetingReservation instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    describe 'self.coming' do
      let(:result) { subject.class.where(not_coming: false).limit(20) }

      it "contains only athlete reservations that haven't been flagged as 'not coming'" do
        expect(result).to all(be_coming)
      end
    end

    describe 'self.unpayed' do
      let(:result) { subject.class.where(payed: false).limit(20) }

      it "contains only athlete reservations that haven't been flagged as 'payed'" do
        result.all? { |res| expect(res.payed?).to be false }
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#coming?' do
      context 'for reservations that are not flagged for skipping' do
        subject { fixture_row.coming? }

        let(:fixture_row) { FactoryBot.create(:meeting_reservation, not_coming: false) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'for reservations that are flagged for skipping' do
        subject { fixture_row.coming? }

        let(:fixture_row) { FactoryBot.create(:meeting_reservation, not_coming: true) }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe '#minimal_attributes' do
      subject { described_class.limit(200).sample.minimal_attributes }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end

      %w[
        display_label short_label
        badge team swimmer
      ].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      # Required associations:
      context 'for required associations,' do
        subject { FactoryBot.create(:meeting_reservation) }

        let(:json_hash) { JSON.parse(subject.to_json) }

        %w[display_label short_label].each do |method_name|
          it "includes the decorated '#{method_name}'" do
            expect(json_hash[method_name]).to eq(subject.decorate.send(method_name))
          end
        end

        it_behaves_like(
          '#to_json when called on a valid instance',
          %w[badge team swimmer user]
        )
        it_behaves_like(
          '#to_json when called on a valid instance with a synthetized association',
          %w[meeting]
        )
      end

      # Collection associations:
      context 'for collection associations,' do
        context 'when the entity has MERes,' do
          subject do
            mer = GogglesDb::MeetingEventReservation.limit(100).sample
            expect(mer.meeting_reservation).to be_a(described_class).and be_valid
            mer.meeting_reservation
          end

          let(:json_hash) { JSON.parse(subject.to_json) }

          it_behaves_like(
            '#to_json when the entity contains collection associations with',
            %w[meeting_event_reservations]
          )
        end

        context 'when the entity has MRRes,' do
          subject do
            mrr = GogglesDb::MeetingRelayReservation.limit(100).sample
            expect(mrr.meeting_reservation).to be_a(described_class).and be_valid
            mrr.meeting_reservation
          end

          let(:json_hash) { JSON.parse(subject.to_json) }

          it_behaves_like(
            '#to_json when the entity contains collection associations with',
            %w[meeting_relay_reservations]
          )
        end
      end
    end
  end
end
