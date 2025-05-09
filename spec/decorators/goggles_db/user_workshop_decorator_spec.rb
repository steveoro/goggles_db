# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::UserWorkshopDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { Prosopite.pause { FactoryBot.create(:workshop_with_results) } }

  before do
    expect(fixture_row).to be_a(GogglesDb::UserWorkshop).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Season type name' do
        expect(result).to include(fixture_row.season_type.short_name)
      end

      it 'includes the name with the edition number (AbstractMeeting#name_with_edition)' do
        expect(result).to include(fixture_row.name_with_edition)
      end
    end
  end

  describe '#short_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the short name with the edition number (AbstractMeeting#condensed_name)' do
        expect(result).to include(fixture_row.name_with_edition(fixture_row.condensed_name))
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe '#scheduled_dates' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.scheduled_dates }

      it 'returns the list of unique scheduled dates for all Meeting session' do
        expect(result).to match_array(fixture_row.user_results.map(&:event_date).uniq)
      end
    end

    context 'when there are no results,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:user_workshop)).scheduled_dates }

      it 'returns an empty list' do
        expect(result).to eq([])
      end
    end
  end

  describe '#scheduled_date' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.scheduled_date }

      it 'returns the first scheduled date found' do
        expect(result).to eq(decorated_instance.scheduled_dates&.first)
      end
    end

    context 'when there are no results,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:user_workshop)).scheduled_date }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#meeting_date' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.meeting_date }

      it 'returns either the #scheduled_date or the #header_date, depending on what is defined' do
        expect(result).to eq(decorated_instance.scheduled_date).or eq(fixture_row.header_date)
      end
    end

    context 'when there are no results,' do
      subject(:result) { described_class.decorate(fixture_row).meeting_date }

      let(:fixture_row) { FactoryBot.create(:user_workshop) }

      it 'returns the #header_date' do
        expect(result).to eq(fixture_row.header_date)
      end
    end
  end

  describe '#meeting_pools' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.meeting_pools }

      it 'returns the list of uniquely defined swimming pools' do
        expect(result).to match_array(fixture_row.user_results.map(&:swimming_pool).uniq)
      end
    end

    context 'when there are no results,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:user_workshop)).meeting_pools }

      it 'returns an empty list' do
        expect(result).to eq([])
      end
    end
  end

  describe '#meeting_pool' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.meeting_pool }

      it 'returns the first swimming pool found' do
        expect(result).to eq(decorated_instance.meeting_pools&.first)
      end
    end

    context 'when there are no results and no default pool is set on the workshop,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:user_workshop)).meeting_pool }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#event_type_list' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.event_type_list }

      it 'returns the list of all the uniquely defined event types' do
        expect(result).to match_array(decorated_instance.user_results.map(&:event_type).flatten.uniq)
      end
    end

    context 'when there are no results,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:user_workshop)).event_type_list }

      it 'returns an empty list' do
        expect(result).to eq([])
      end
    end
  end
end
