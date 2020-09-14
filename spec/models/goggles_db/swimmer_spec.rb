# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe Swimmer, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:swimmer) }

      it 'is valid' do
        expect(subject).to be_a(Swimmer).and be_valid
      end
      it 'is has a valid GenderType' do
        expect(subject).to respond_to(:gender_type)
        expect(subject.gender_type).to be_a(GenderType).and be_valid
      end
      it 'is does not have an associated user yet' do
        expect(subject).to respond_to(:associated_user)
        expect(subject.associated_user).to be nil
      end
      it 'is has a #complete_name' do
        expect(subject).to respond_to(:complete_name)
        expect(subject.complete_name).to be_present
      end
      it 'is has a #year_of_birth' do
        expect(subject).to respond_to(:year_of_birth)
        expect(subject.year_of_birth).to be_present
      end
    end
  end
end
