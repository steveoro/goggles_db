# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_localizable_examples'

module GogglesDb
  RSpec.describe SwimmerLevelType do
    context 'any pre-seeded instance' do
      subject { described_class.all.sample }

      it 'is valid' do
        expect(subject).to be_valid
      end

      it_behaves_like('Localizable')
      it_behaves_like('ApplicationRecord shared interface')

      it 'has a #code' do
        expect(subject.code).to be_present
      end
    end
  end
end
