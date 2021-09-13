# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_localizable_examples'

module GogglesDb
  RSpec.describe EventType, type: :model do
    context 'any pre-seeded instance' do
      subject { (described_class.all_individuals + described_class.all_relays).sample }

      it 'is valid' do
        expect(subject).to be_an(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[stroke_type]
      )
      it_behaves_like(
        'responding to a list of methods',
        %i[relay?]
      )

      it_behaves_like('Localizable')

      it 'has a #code' do
        expect(subject.code).to be_present
      end

      %w[length_in_meters partecipants phases phase_length_in_meters
         style_order].each do |member|
        it "has a positive ##{member}" do
          expect(subject.send(member)).to be_positive
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Scopes & virtual scopes:
    describe 'self.all_relays' do
      let(:result) { subject.class.all_relays }

      it 'is an array of relay-only event types' do
        expect(result).to be_an(Array)
        expect(result).to all(be_relay)
      end
    end

    describe 'self.all_individuals' do
      let(:result) { subject.class.all_individuals }

      it 'is an array of individual-only event types' do
        expect(result).to be_an(Array)
        result.each do |row|
          expect(row.relay?).to be false
        end
      end
    end

    describe 'self.all_eventable' do
      let(:result) { subject.class.all_eventable }

      it 'is an array of event types based on an actual eventable stroke type' do
        expect(result).to be_an(Array)
        result.each do |row|
          expect(row.stroke_type.eventable?).to be true
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
