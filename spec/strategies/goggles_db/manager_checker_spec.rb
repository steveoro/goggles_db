# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe ManagerChecker, type: :strategy do
    it_behaves_like(
      'responding to a list of class methods',
      %i[for_affiliation?]
    )

    let(:basic_user) { FactoryBot.create(:user) }
    let(:admin_user) { User.first }
    let(:team_crud_grant) { FactoryBot.create(:admin_grant, entity: 'Team') }
    let(:affiliation_crud_grant) { FactoryBot.create(:admin_grant, entity: 'TeamAffiliation') }
    let(:another_crud_grant) { FactoryBot.create(:admin_grant, entity: 'AnythingElse') }

    let(:managed_affiliation) { FactoryBot.create(:managed_affiliation) }
    let(:fixture_affiliation) { managed_affiliation.team_affiliation }
    let(:team_manager) { managed_affiliation.manager }

    before(:each) do
      expect(basic_user).to be_a(User).and be_valid
      expect(admin_user).to be_a(User).and be_valid
      expect(team_crud_grant).to be_a(AdminGrant).and be_valid
      expect(affiliation_crud_grant).to be_a(AdminGrant).and be_valid
      expect(another_crud_grant).to be_a(AdminGrant).and be_valid

      expect(managed_affiliation).to be_a(ManagedAffiliation).and be_valid
      expect(team_manager).to be_a(User).and be_valid
      expect(fixture_affiliation).to be_a(TeamAffiliation).and be_valid
    end

    describe 'self.for_affiliation?' do
      context 'when the user is a Team Manager for the specified affiliation,' do
        subject { described_class.for_affiliation?(team_manager, fixture_affiliation) }
        it 'is true' do
          expect(subject).to be true
        end
      end
      context 'when the user has generic admin rights,' do
        subject { described_class.for_affiliation?(admin_user, fixture_affiliation) }
        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject { described_class.for_affiliation?(affiliation_crud_grant.user, fixture_affiliation) }
        it 'is true' do
          expect(subject).to be true
        end
      end
      context 'when the user has CRUD rights for a generic Team,' do
        subject { described_class.for_affiliation?(team_crud_grant.user, fixture_affiliation) }
        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have any specific grants (basic user),' do
        subject { described_class.for_affiliation?(basic_user, fixture_affiliation) }
        it 'is false' do
          expect(subject).to be false
        end
      end
      context 'when the user has CRUD rights for a different entity,' do
        subject { described_class.for_affiliation?(another_crud_grant.user, fixture_affiliation) }
        it 'is false' do
          expect(subject).to be false
        end
      end
    end
  end
end
