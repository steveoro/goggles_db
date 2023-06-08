# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'

module GogglesDb
  RSpec.describe FederationType do
    %w[fin csi uisp len fina].each do |word|
      describe "self.#{word}" do
        subject { described_class.send(word) }

        it_behaves_like('ApplicationRecord shared interface')

        it 'is a valid instance of the same class' do
          expect(subject).to be_a(described_class).and be_valid
        end

        it 'has a #code' do
          expect(subject.code).to be_a(String).and be_present
        end

        it 'has a #description' do
          expect(subject.description).to be_a(String).and be_present
        end

        it 'has a #short_name' do
          expect(subject.short_name).to be_a(String).and be_present
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
