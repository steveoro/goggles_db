# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existence_examples'

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

    it 'responds to self.admin?()' do
      expect(described_class).to respond_to(:admin?)
    end

    it 'responds to #admin?' do
      expect(described_class.new(basic_user)).to respond_to(:admin?)
    end

    it 'responds to self.crud?()' do
      expect(described_class).to respond_to(:crud?)
    end

    it 'responds to #crud?' do
      expect(described_class.new(basic_user)).to respond_to(:crud?)
    end

    context 'when the user is not a valid instance,' do
      it 'raises an ArgumentError' do
        expect { described_class.new('not-a-user') }.to raise_error(ArgumentError)
      end
    end
    #--------------------------------------------------------------------------

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
    #--------------------------------------------------------------------------

    describe '#admin?' do
      context 'when the user has generic admin rights,' do
        subject { described_class.new(admin_user).admin? }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have generic admin rights (basic user),' do
        subject { described_class.new(basic_user).admin? }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has just CRUD rights for a specific entity,' do
        subject { described_class.new(crud_user).admin? }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end
    #--------------------------------------------------------------------------

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
    #--------------------------------------------------------------------------

    describe '#crud?' do
      context 'when the user has generic admin rights,' do
        subject { described_class.new(admin_user).crud?(fixture_entity) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have any specific grants (basic user),' do
        subject { described_class.new(basic_user).crud?(fixture_entity) }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has just CRUD rights for a different entity,' do
        subject { described_class.new(basic_user).crud?('A_DIFFERENT_ENTITY_FOR_SURE!') }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject { described_class.new(crud_user).crud?(fixture_entity) }

        it 'is true' do
          expect(subject).to be true
        end
      end
    end
    #--------------------------------------------------------------------------
  end
end
