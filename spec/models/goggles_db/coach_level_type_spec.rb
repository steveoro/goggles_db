# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_localizable_examples'

module GogglesDb
  RSpec.describe CoachLevelType do
    context 'any pre-seeded instance' do
      subject { described_class.all.sample }

      it 'is valid' do
        expect(subject).to be_valid
      end

      it_behaves_like('Localizable')
      it_behaves_like('ApplicationRecord shared interface')
    end

    (described_class::MIN_LEVEL_ID..described_class::MAX_LEVEL_ID).each do |level_id|
      describe "self.level_#{level_id}" do
        let(:method_name) { "level_#{level_id}" }

        it 'has a #code' do
          expect(subject.class.send(method_name)).to respond_to(:code)
          expect(subject.class.send(method_name).code).to be_present
        end

        it 'is a valid instance of the same class' do
          expect(subject.class.send(method_name)).to be_a(subject.class).and be_valid
        end
      end
    end

    describe 'self.validate_cached_rows' do
      it 'does not raise any errors' do
        expect { described_class.validate_cached_rows }.not_to raise_error
      end
    end
  end
end
