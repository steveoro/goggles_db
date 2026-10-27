# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::GogglesCup::BadgeProvisioner do
  let(:team) { FactoryBot.create(:team) }
  let(:cup) { FactoryBot.create(:goggle_cup, team: team, swimmers_ids: nil) }

  # The provisioner targets the latest MASFIN season of the current championship
  # year; the fixture DB carries real seasons, so resolve it the same way.
  let(:target_season) do
    year = GogglesDb::Season.current_championship_year(GogglesDb::SeasonType.mas_fin)
    GogglesDb::Season.for_season_type(GogglesDb::SeasonType.mas_fin)
                     .for_championship_year(year)
                     .first
  end

  it 'returns an empty report when no swimmers are enlisted' do
    report = described_class.new(cup).call
    expect(report).to eq(created: [], existing: [], skipped: [])
  end

  context 'with enlisted swimmers' do
    let(:swimmer) { FactoryBot.create(:swimmer, year_of_birth: 1990) }
    let(:cup) { FactoryBot.create(:goggle_cup, team: team, swimmers_ids: "#{swimmer.id},999999") }

    before { skip('no MASFIN season for the current championship year in fixtures') if target_season.nil? }

    it 'creates the missing badge on the latest MASFIN season' do
      report = described_class.new(cup).call
      created = report[:created].find { |badge| badge.swimmer_id == swimmer.id }
      expect(created).to be_a(GogglesDb::Badge).and be_persisted
      expect(created.season_id).to eq(target_season.id)
      expect(created.team_id).to eq(team.id)
      expect(created.number).to eq('?')
      expect(created.entry_time_type_id).to eq(GogglesDb::EntryTimeType::GOGGLECUP_ID)
    end

    it 'auto-creates the team affiliation flagged as autofilled' do
      expect { described_class.new(cup).call }
        .to change(GogglesDb::TeamAffiliation, :count).by(1)
      affiliation = GogglesDb::TeamAffiliation.find_by(team_id: team.id, season_id: target_season.id)
      expect(affiliation).to be_present.and have_attributes(autofilled: true)
      expect(GogglesDb::Badge.where(swimmer_id: swimmer.id, season_id: target_season.id)
                             .pluck(:team_affiliation_id)).to eq([affiliation.id])
    end

    it 'reports unknown swimmer ids as skipped' do
      report = described_class.new(cup).call
      expect(report[:skipped]).to include({ swimmer_id: 999_999, reason: :swimmer_not_found })
    end

    it 'is idempotent: a second run reports the badge as existing' do
      described_class.new(cup).call
      report = described_class.new(cup).call
      expect(report[:created]).to be_empty
      expect(report[:existing].map(&:swimmer_id)).to include(swimmer.id)
    end

    it 'reuses an already-existing team affiliation' do
      FactoryBot.create(:team_affiliation, team: team, season: target_season)
      expect { described_class.new(cup).call }
        .not_to change(GogglesDb::TeamAffiliation, :count)
    end
  end
end
