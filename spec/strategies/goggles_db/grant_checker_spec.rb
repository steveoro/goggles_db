# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe GrantChecker, type: :strategy do
    let(:crud_grant) { FactoryBot.create(:admin_grant, user: crud_user, entity: fixture_entity) }
    let(:fixture_entity) { FFaker::Lorem.word.titleize }
    let(:crud_user)  { FactoryBot.create(:user) }
    let(:admin_user) { User.first }
    let(:basic_user) { FactoryBot.create(:user) }

    before do
      expect(basic_user).to be_a(User).and be_valid
      expect(admin_user).to be_a(User).and be_valid
      expect(crud_user).to be_a(User).and be_valid
      expect(crud_grant).to be_a(AdminGrant).and be_valid
    end

    it_behaves_like(
      'responding to a list of class methods',
      %i[admin? crud?]
    )

    describe 'self.admin?' do
      context 'when the user has generic admin rights,' do
        subject { described_class.admin?(admin_user) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user is not a valid instance,' do
        subject { described_class.admin?(nil) }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user does not have generic admin rights (basic user),' do
        subject { described_class.admin?(basic_user) }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has just CRUD rights for a specific entity,' do
        subject { described_class.admin?(crud_user) }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe 'self.crud?' do
      context 'when the user has generic admin rights,' do
        subject { described_class.crud?(admin_user, fixture_entity) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have any specific grants (basic user),' do
        subject { described_class.crud?(basic_user, fixture_entity) }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has just CRUD rights for a different entity,' do
        subject { described_class.crud?(crud_user, 'A_DIFFERENT_ENTITY_FOR_SURE!') }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject { described_class.crud?(crud_user, fixture_entity) }

        it 'is true' do
          expect(subject).to be true
        end
      end
    end
  end
end
