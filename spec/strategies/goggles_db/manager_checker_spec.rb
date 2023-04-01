# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe ManagerChecker, type: :strategy do
    let(:managed_affiliation) { FactoryBot.create(:managed_affiliation) }
    let(:team_manager) { managed_affiliation.manager }
    let(:fixture_affiliation) { managed_affiliation.team_affiliation }
    let(:fixture_badge) { GogglesDb::Badge.last(200).sample }
    let(:ta_from_fixture_badge) do
      GogglesDb::TeamAffiliation.where(season_id: fixture_badge.season_id, team_id: fixture_badge.team_id).first ||
        FactoryBot.create(:team_affiliation, season: fixture_badge.season, team: fixture_badge.team)
    end
    let(:managed_aff_for_badge) { FactoryBot.create(:managed_affiliation, team_affiliation: ta_from_fixture_badge) }
    let(:team_manager_for_badge) { managed_aff_for_badge.manager }

    let(:random_affiliation) { GogglesDb::TeamAffiliation.last(50).sample }
    let(:random_team) { GogglesDb::Team.last(50).sample }
    let(:random_badge) { GogglesDb::Badge.last(50).sample }

    let(:another_crud_grant) { FactoryBot.create(:admin_grant, entity: 'AnythingElse') }
    let(:affiliation_crud_grant) { FactoryBot.create(:admin_grant, entity: 'TeamAffiliation') }
    let(:team_crud_grant) { FactoryBot.create(:admin_grant, entity: 'Team') }
    let(:swimmer_crud_grant) { FactoryBot.create(:admin_grant, entity: 'Swimmer') }
    let(:badge_crud_grant) { FactoryBot.create(:admin_grant, entity: 'Badge') }

    let(:admin_user) { User.first }
    let(:basic_user) { FactoryBot.create(:user) }

    before do
      expect(basic_user).to be_a(User).and be_valid
      expect(admin_user).to be_a(User).and be_valid

      expect(team_crud_grant).to be_a(AdminGrant).and be_valid
      expect(swimmer_crud_grant).to be_a(AdminGrant).and be_valid
      expect(badge_crud_grant).to be_a(AdminGrant).and be_valid
      expect(affiliation_crud_grant).to be_a(AdminGrant).and be_valid
      expect(another_crud_grant).to be_a(AdminGrant).and be_valid

      expect(managed_affiliation).to be_a(ManagedAffiliation).and be_valid
      expect(fixture_affiliation).to be_a(TeamAffiliation).and be_valid
      expect(team_manager).to be_a(User).and be_valid

      expect(fixture_badge).to be_a(Badge).and be_valid
      expect(ta_from_fixture_badge).to be_a(TeamAffiliation).and be_valid
      expect(managed_aff_for_badge).to be_a(ManagedAffiliation).and be_valid
      expect(team_manager_for_badge).to be_a(User).and be_valid

      expect(random_affiliation).to be_a(TeamAffiliation).and be_valid
      expect(random_team).to be_a(Team).and be_valid
      expect(random_badge).to be_a(Badge).and be_valid
    end

    describe 'self.for_affiliation?()' do
      context 'when the user is a Team Manager for the specified affiliation,' do
        subject { described_class.for_affiliation?(team_manager, fixture_affiliation.id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has generic admin rights,' do
        subject { described_class.for_affiliation?(admin_user, random_affiliation.id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject { described_class.for_affiliation?(affiliation_crud_grant.user, random_affiliation.id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for a generic Team,' do
        subject { described_class.for_affiliation?(team_crud_grant.user, random_affiliation.id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have any specific grants (basic user),' do
        subject { described_class.for_affiliation?(basic_user, fixture_affiliation.id) }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has CRUD rights for a different entity,' do
        subject { described_class.for_affiliation?(another_crud_grant.user, fixture_affiliation.id) }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.any_for?()' do
      context 'when the user is a Team Manager for the specified season,' do
        subject { described_class.any_for?(team_manager, fixture_affiliation.season_id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has generic admin rights,' do
        subject { described_class.any_for?(admin_user, random_affiliation.season_id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject { described_class.any_for?(affiliation_crud_grant.user, random_affiliation.season_id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for a generic Team,' do
        subject { described_class.any_for?(team_crud_grant.user, random_affiliation.season_id) }

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have any specific grants (basic user),' do
        subject { described_class.any_for?(basic_user, fixture_affiliation.season_id) }

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has CRUD rights for a different entity,' do
        subject { described_class.any_for?(another_crud_grant.user, fixture_affiliation.season_id) }

        it 'is false' do
          expect(subject).to be false
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#for_team?' do
      context 'when the user is a Team Manager for the specified team,' do
        subject do
          described_class.new(team_manager, fixture_affiliation.season_id)
                         .for_team?(fixture_affiliation.team_id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has generic admin rights,' do
        subject do
          described_class.new(admin_user, random_affiliation.season_id)
                         .for_team?(random_team.id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject do
          described_class.new(affiliation_crud_grant.user, random_affiliation.season_id)
                         .for_team?(random_team.id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for a generic Team,' do
        subject do
          described_class.new(team_crud_grant.user, random_affiliation.season_id)
                         .for_team?(random_team.id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have any specific grants (basic user),' do
        subject do
          described_class.new(basic_user, fixture_affiliation.season_id)
                         .for_team?(fixture_affiliation.team_id)
        end

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has CRUD rights for a different entity,' do
        subject do
          described_class.new(another_crud_grant.user, fixture_affiliation.season_id)
                         .for_team?(fixture_affiliation.team_id)
        end

        it 'is false' do
          expect(subject).to be false
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#for_swimmer?' do
      context 'when the user is a Team Manager for any team of the swimmer,' do
        subject do
          described_class.new(team_manager_for_badge, fixture_badge.season_id)
                         .for_swimmer?(fixture_badge.swimmer_id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has generic admin rights,' do
        subject do
          described_class.new(admin_user, random_badge.season_id)
                         .for_swimmer?(random_badge.swimmer_id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for the same entity we are checking for,' do
        subject do
          described_class.new(swimmer_crud_grant.user, random_badge.season_id)
                         .for_swimmer?(random_badge.swimmer_id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user has CRUD rights for a generic Badge,' do
        subject do
          described_class.new(badge_crud_grant.user, random_badge.season_id)
                         .for_swimmer?(random_badge.swimmer_id)
        end

        it 'is true' do
          expect(subject).to be true
        end
      end

      context 'when the user does not have any specific grants (basic user),' do
        subject do
          described_class.new(basic_user, fixture_badge.season_id)
                         .for_swimmer?(fixture_badge.swimmer_id)
        end

        it 'is false' do
          expect(subject).to be false
        end
      end

      context 'when the user has CRUD rights for a different entity,' do
        subject do
          described_class.new(another_crud_grant.user, fixture_badge.season_id)
                         .for_swimmer?(fixture_badge.swimmer_id)
        end

        it 'is false' do
          expect(subject).to be false
        end
      end
    end
    #-- ------------------------------------------------------------------------
    #++
  end
end
