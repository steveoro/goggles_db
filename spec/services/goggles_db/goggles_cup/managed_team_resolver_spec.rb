# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GogglesCup::ManagedTeamResolver do
  subject(:resolver) { described_class.new(user: user, season_year: season_year) }

  let(:user) { FactoryBot.create(:user) }
  let(:season_year) { 2024 }
  let!(:shown_season) do
    FactoryBot.create(:season, season_type_id: GogglesDb::SeasonType::MAS_FIN_ID,
                               begin_date: Date.new(season_year, 9, 1),
                               end_date: Date.new(season_year + 1, 6, 30))
  end

  context 'with an admin user' do
    before { allow(GogglesDb::GrantChecker).to receive(:admin?).with(user).and_return(true) }

    it 'can choose any team' do
      expect(resolver.can_choose_any_team?).to be(true)
    end

    it 'has an unrestricted (empty) managed teams list' do
      expect(resolver.managed_teams).to be_empty
    end

    it 'still defaults to the team of a managed affiliation for the shown year, if any' do
      affiliation = FactoryBot.create(:team_affiliation, season: shown_season)
      FactoryBot.create(:managed_affiliation, manager: user, team_affiliation: affiliation)
      expect(resolver.default_team).to eq(affiliation.team)
    end
  end

  context 'with a team manager user' do
    before { allow(GogglesDb::GrantChecker).to receive(:admin?).with(user).and_return(false) }

    let!(:managed_affiliation) do
      FactoryBot.create(:managed_affiliation, manager: user,
                                              team_affiliation: FactoryBot.create(:team_affiliation, season: shown_season))
    end

    it 'cannot choose any team' do
      expect(resolver.can_choose_any_team?).to be(false)
    end

    it 'lists the managed teams' do
      expect(resolver.managed_teams).to include(managed_affiliation.team_affiliation.team)
    end

    it 'defaults to the team of the managed affiliation for the shown year' do
      expect(resolver.default_team).to eq(managed_affiliation.team_affiliation.team)
    end

    context 'when the managed affiliation is on another season' do
      let(:other_season) do
        FactoryBot.create(:season, season_type_id: GogglesDb::SeasonType::MAS_FIN_ID,
                                   begin_date: Date.new(season_year - 5, 9, 1),
                                   end_date: Date.new(season_year - 4, 6, 30))
      end

      before do
        managed_affiliation.team_affiliation.update!(season: other_season)
      end

      it 'is still listed among the managed teams' do
        expect(resolver.managed_teams).to include(managed_affiliation.team_affiliation.team)
      end

      context 'when restricted to the shown season' do
        subject(:resolver) do
          described_class.new(user: user, season_year: season_year, restrict_to_shown_season: true)
        end

        it 'is not listed among the managed teams' do
          expect(resolver.managed_teams).not_to include(managed_affiliation.team_affiliation.team)
        end
      end

      it 'falls back to the team of the user swimmer badge for the shown year' do
        swimmer = FactoryBot.create(:swimmer)
        user.update!(swimmer: swimmer)
        badge_affiliation = FactoryBot.create(:team_affiliation, season: shown_season)
        badge = FactoryBot.create(:badge, team_affiliation: badge_affiliation, season: shown_season,
                                          team: badge_affiliation.team, swimmer: swimmer,
                                          category_type: FactoryBot.create(:category_type, season: shown_season))
        expect(resolver.default_team).to eq(badge.team)
      end

      it 'returns nil without a managed affiliation or a badge for the shown year' do
        expect(resolver.default_team).to be_nil
      end
    end
  end
end
