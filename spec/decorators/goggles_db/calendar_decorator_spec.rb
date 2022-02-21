# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::CalendarDecorator, type: :decorator do
  context 'for a row with an associated Meeting,' do
    subject(:decorated_instance) { described_class.decorate(fixture_row) }

    let(:fixture_row) { FactoryBot.create(:calendar) }

    before do
      expect(fixture_row).to be_a(GogglesDb::Calendar).and be_valid
      expect(fixture_row.meeting).to be_a(GogglesDb::Meeting).and be_valid
      expect(decorated_instance).to be_a(described_class).and be_valid
    end

    describe '#display_label' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'is the decorated Meeting display_label' do
        expect(result).to eq(fixture_row.meeting.decorate.display_label)
      end
    end

    describe '#short_label' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'is the decorated Meeting short_label' do
        expect(result).to eq(fixture_row.meeting.decorate.short_label)
      end
    end

    describe '#meeting_date' do
      subject(:result) { decorated_instance.meeting_date }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'is the scheduled or header date from the decorated Meeting as an ISO string' do
        expect(result).to eq(fixture_row.meeting.decorate.meeting_date.to_s)
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  context 'for a row without an associated Meeting,' do
    subject(:decorated_instance) { described_class.decorate(fixture_row) }

    let(:fixture_row) { GogglesDb::Calendar.where(meeting_id: nil).first(300).sample }

    before do
      expect(fixture_row).to be_a(GogglesDb::Calendar).and be_valid
      expect(decorated_instance).to be_a(described_class).and be_valid
    end

    describe '#display_label' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Season type short name' do
        expect(result).to include(fixture_row.season_type.short_name)
      end

      it 'includes the scheduled date' do
        expect(result).to include(fixture_row.scheduled_date)
      end

      it 'includes the meeting name (when defined; a question mark otherwise)' do
        if fixture_row.meeting_name.present?
          expect(result).to include(fixture_row.meeting_name)
        else
          expect(result).to include('?')
        end
      end
    end

    describe '#short_label' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Season type short name' do
        expect(result).to include(fixture_row.season_type.short_name)
      end

      it 'includes the meeting year' do
        expect(result).to include(fixture_row.year)
      end

      it 'includes the meeting name (when defined; a question mark otherwise)' do
        if fixture_row.meeting_name.present?
          expect(result).to include(fixture_row.meeting_name)
        else
          expect(result).to include('?')
        end
      end
    end

    describe '#meeting_date' do
      subject(:result) { decorated_instance.meeting_date }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'is the scheduled date from the calendar' do
        expect(result).to eq(fixture_row.scheduled_date)
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
