# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe User, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:user) }

      it_behaves_like(
        'having one or more required associations',
        %i[swimmer_level_type]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[swimmer coach_level_type]
      )
      #-- ----------------------------------------------------------------------
      #++

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
