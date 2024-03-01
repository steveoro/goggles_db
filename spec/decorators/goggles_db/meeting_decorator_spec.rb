# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::MeetingDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::Meeting.first(300).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::Meeting).and be_valid
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

      it 'returns the list of uniquely defined scheduled dates' do
        expect(result).to match_array(fixture_row.meeting_sessions.map(&:scheduled_date).uniq) if result.present?
      end
    end

    context 'when there are no sessions,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:meeting)).scheduled_dates }

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

    context 'when there are no sessions,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:meeting)).scheduled_date }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#meeting_date' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.meeting_date }

      it 'returns either the #scheduled_date or the #header_date, depending on what is defined' do
        expect(result).to eq(decorated_instance.scheduled_dates&.first).or eq(fixture_row.header_date)
      end
    end

    context 'when there are no sessions,' do
      subject(:result) { described_class.decorate(fixture_row).meeting_date }

      let(:fixture_row) { FactoryBot.create(:meeting) }

      it 'returns the #header_date' do
        expect(result).to eq(fixture_row.header_date)
      end
    end
  end

  describe '#meeting_pools' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.meeting_pools }

      it 'returns the list of uniquely defined swimming pools' do
        expect(result).to match_array(fixture_row.meeting_sessions.by_order.map(&:swimming_pool).uniq) if result.present?
      end
    end

    context 'when there are no sessions,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:meeting)).meeting_pools }

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

    context 'when there are no sessions,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:meeting)).meeting_pool }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#event_list' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.event_list }

      it 'returns the list of all the uniquely defined events' do
        expect(result).to match_array(
          fixture_row.meeting_sessions.includes(:meeting_events).by_order.map(&:meeting_events).flatten
        )
      end
    end

    context 'when there are no sessions,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:meeting)).event_list }

      it 'returns an empty list' do
        expect(result).to eq([])
      end
    end
  end

  describe '#event_type_list' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.event_type_list }

      it 'returns the list of all the uniquely defined event types' do
        expect(result).to match_array(
          decorated_instance.event_list.map(&:event_type)
        )
      end
    end

    context 'when there are no sessions,' do
      subject(:result) { described_class.decorate(FactoryBot.create(:meeting)).event_type_list }

      it 'returns an empty list' do
        expect(result).to eq([])
      end
    end
  end
end
