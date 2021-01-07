# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe TimingFinders::NoTimeForEvent, type: :strategy do
    it_behaves_like('responding to a list of methods', %i[search_by])

    describe '#search_by' do
      context 'it is always a  MIRs,' do
        subject { TimingFinders::NoTimeForEvent.new.search_by(FFaker::Lorem.word, nil, FFaker::Lorem.word, FFaker::Lorem.word) }

        it 'does not raise any error because it ignores its parameters' do
          expect { subject }.not_to raise_error
        end
        it 'is always a MeetingIndividualResult' do
          expect(subject).to be_a(MeetingIndividualResult)
        end
        it 'stores a zeroed timing result' do
          expect(subject.to_timing).to eq(Timing.new)
        end
      end
    end
  end
end
