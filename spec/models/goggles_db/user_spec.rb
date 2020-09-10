# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe User, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user) }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end
end
