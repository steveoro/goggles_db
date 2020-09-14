# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe User, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user) }

      it 'is valid' do
        expect(subject).to be_a(User).and be_valid
      end
      it 'is has a #name' do
        expect(subject).to respond_to(:name)
        expect(subject.name).to be_present
      end
      it 'is has an #email' do
        expect(subject).to respond_to(:email)
        expect(subject.email).to be_present
      end
    end
  end
end
