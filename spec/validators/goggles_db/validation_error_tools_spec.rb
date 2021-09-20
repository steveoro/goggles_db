# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe ValidationErrorTools, type: :validator do
    describe 'self.recursive_error_for' do
      context 'with a valid instance,' do
        subject { described_class.recursive_error_for(valid_user) }

        let(:valid_user) { FactoryBot.create(:user) }

        it 'returns an empty message (no errors)' do
          expect(subject).to be_a(String).and be_empty
        end
      end

      context 'with an invalid instance (invalid at 0-level),' do
        subject { described_class.recursive_error_for(invalid_swimmer) }

        let(:invalid_swimmer) { FactoryBot.build(:swimmer, gender_type_id: 0) }

        it 'returns the error message' do
          expect(subject).to be_a(String).and be_present
        end
      end
    end
  end
end
