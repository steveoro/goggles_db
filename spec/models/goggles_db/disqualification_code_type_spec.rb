# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_localizable_examples'

module GogglesDb
  RSpec.describe DisqualificationCodeType, type: :model do
    context 'any pre-seeded instance' do
      subject { DisqualificationCodeType.all.sample }

      it 'is valid' do
        expect(subject).to be_a(DisqualificationCodeType).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[stroke_type false_start? retired? relay?]
      )

      it_behaves_like('Localizable')

      it 'has a #code' do
        expect(subject.code).to be_present
      end
    end
  end
end
