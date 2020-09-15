# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe EventType, type: :model do
    context 'any seeded instance' do
      subject { (EventType.only_individuals + EventType.only_relays).sample }

      it 'is valid' do
        expect(subject).to be_an(EventType).and be_valid
      end

      it 'is has a #code' do
        expect(subject.code).to be_present
      end

      %w[length_in_meters partecipants phases phase_length_in_meters
         style_order].each do |member|
        it "is has a positive ##{member}" do
          expect(subject.send(member)).to be_positive
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Scopes & virtual scopes:
    describe 'self.only_relays' do
      it 'is an array of relay-only event types' do
        expect(subject.class.only_relays).to be_an(Array)
        expect(subject.class.only_relays).to all(be_relay)
      end
    end

    describe 'self.only_individuals' do
      it 'is an array of individual-only event types' do
        expect(subject.class.only_individuals).to be_an(Array)
        subject.class.only_individuals.each do |row|
          expect(row.relay?).to be false
        end
      end
    end

    # TODO: for_season_type
    # TODO: for_season
    #-- ------------------------------------------------------------------------
    #++
  end
end
