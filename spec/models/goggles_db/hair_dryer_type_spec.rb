# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_localizable_examples'

module GogglesDb
  RSpec.describe HairDryerType, type: :model do
    context 'any pre-seeded instance' do
      subject { described_class.all.sample }

      it 'is valid' do
        expect(subject).to be_valid
      end

      it_behaves_like('Localizable')
    end
  end
end
