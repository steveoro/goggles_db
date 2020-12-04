# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe GrantChecker, type: :strategy do
    it_behaves_like(
      'responding to a list of class methods',
      %i[admin? crud?]
    )

    let(:basic_user) { FactoryBot.create(:user) }
    let(:admin_user) { User.first }
    let(:crud_user)  { FactoryBot.create(:user) }

    let(:fixture_entity) { FFaker::Lorem.word.titleize }
    let(:crud_grant) { FactoryBot.create(:admin_grant, user: crud_user, entity: fixture_entity) }

    before(:each) do
      expect(basic_user).to be_a(User).and be_valid
      expect(admin_user).to be_a(User).and be_valid
      expect(crud_user).to be_a(User).and be_valid
      expect(crud_grant).to be_a(AdminGrant).and be_valid
    end

    describe 'self.admin?' do
      context 'when the user has generic admin rights,' do
        subject { GrantChecker.admin?(admin_user) }
        it 'is true' do
          expect(subject).to be true
        end
      end
      context 'when the user does not have generic admin rights (basic user),' do
        subject { GrantChecker.admin?(basic_user) }
        it 'is false' do
          expect(subject).to be false
        end
      end
      context 'when the user has just CRUD rights for a specific entity,' do
        subject { GrantChecker.admin?(crud_user) }
        it 'is false' do
          expect(subject).to be false
        end
      end
    end

    describe 'self.crud?' do
      context 'when the user has generic admin rights,' do
        subject { GrantChecker.crud?(admin_user, fixture_entity) }
        it 'is true' do
          expect(subject).to be true
        end
      end
      context 'when the user does not have any specific grants (basic user),' do
        subject { GrantChecker.crud?(basic_user, fixture_entity) }
        it 'is false' do
          expect(subject).to be false
        end
      end
      context 'when the user has just CRUD rights for a different entity,' do
        subject { GrantChecker.crud?(crud_user, 'A_DIFFERENT_ENTITY_FOR_SURE!') }
        it 'is false' do
          expect(subject).to be false
        end
      end
      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject { GrantChecker.crud?(crud_user, fixture_entity) }
        it 'is true' do
          expect(subject).to be true
        end
      end
    end
  end
end
