# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existence_examples'

module GogglesDb
  RSpec.describe DbFinders::Factory, type: :strategy do
    it 'responds to self.for' do
      expect(described_class).to respond_to(:for)
    end

    describe 'self.for' do
      context 'with an invalid parameter' do
        subject { described_class.for(nil) }

        it 'raises an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'without an actual search term' do
        subject { described_class.for(GogglesDb::Swimmer) }

        it 'raises an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'with an unsupported entity class' do
        subject { described_class.for(GogglesDb::User, name: 'steve') }

        it 'raises an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'for a Swimmer entity' do
        subject { described_class.for(GogglesDb::Swimmer, complete_name: 'steve a') }

        it 'returns a FuzzySwimmer finder' do
          expect(subject).to be_a(DbFinders::FuzzySwimmer)
        end
      end

      context 'for a Team entity' do
        subject { described_class.for(GogglesDb::Team, name: 'ober ferrari') }

        it 'returns a FuzzyTeam finder' do
          expect(subject).to be_a(DbFinders::FuzzyTeam)
        end
      end

      context 'for a SwimmingPool entity' do
        subject { described_class.for(GogglesDb::SwimmingPool, name: 'ferretti') }

        it 'returns a FuzzyPool finder' do
          expect(subject).to be_a(DbFinders::FuzzyPool)
        end
      end

      context 'for a Meeting entity' do
        subject { described_class.for(GogglesDb::Meeting, code: 'csiprova5') }

        it 'returns a FuzzyMeeting finder' do
          expect(subject).to be_a(DbFinders::FuzzyMeeting)
        end
      end

      context 'for a City entity' do
        subject { described_class.for(GogglesDb::City, name: 'reggio emilia') }

        it 'returns a FuzzyCity finder' do
          expect(subject).to be_a(DbFinders::FuzzyCity)
        end
      end
    end
  end
end
