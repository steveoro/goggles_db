# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingReservation, type: :model do
    shared_examples_for 'a valid MeetingReservation instance' do
      it 'is valid' do
        expect(subject).to be_a(MeetingReservation).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting user team badge swimmer
           season season_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[not_coming? confirmed? coming?
           minimal_attributes
           to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { MeetingReservation.all.limit(20).sample }
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
    #-- ------------------------------------------------------------------------
    #++

    describe '#coming?' do
      context 'for reservations that are not flagged for skipping' do
        let(:fixture_row) { FactoryBot.build(:meeting_reservation, not_coming: false) }
        subject { fixture_row.coming? }
        it 'is true' do
          expect(subject).to be true
        end
      end
      context 'for reservations that are flagged for skipping' do
        let(:fixture_row) { FactoryBot.build(:meeting_reservation, not_coming: true) }
        subject { fixture_row.coming? }
        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe '#minimal_attributes' do
      subject { GogglesDb::MeetingReservation.limit(200).sample.minimal_attributes }
      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      %w[badge team swimmer].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_reservation) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[badge team swimmer user]
      )
      it_behaves_like(
        '#to_json when called on a valid instance with a synthetized association',
        %w[meeting]
      )
    end
  end
end
