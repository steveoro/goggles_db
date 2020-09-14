# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe ValidationErrorTools, type: :validator do
    describe 'self.recursive_error_for' do
      context 'for a valid instance,' do
        let(:valid_user) { FactoryBot.create(:user) }
        subject { ValidationErrorTools.recursive_error_for(valid_user) }

        it 'returns an empty message (no errors)' do
          expect(subject).to be_a(String).and be_empty
        end
      end

      context 'for an invalid instance (invalid at 0-level),' do
        let(:invalid_swimmer) { FactoryBot.build(:swimmer, gender_type_id: 0) }
        subject { ValidationErrorTools.recursive_error_for(invalid_swimmer) }

        it 'returns the error message' do
          expect(subject).to be_a(String).and be_present
        end
      end
    end
  end
end
