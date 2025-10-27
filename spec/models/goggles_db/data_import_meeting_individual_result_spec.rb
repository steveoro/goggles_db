# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe DataImportMeetingIndividualResult do
    subject { described_class.new(valid_attributes) }

    let(:valid_attributes) do
      {
        import_key: '1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI',
        phase_file_path: '/test/phase5.json',
        meeting_program_id: 12_345,
        swimmer_id: 456,
        team_id: 789,
        rank: 1,
        minutes: 0,
        seconds: 58,
        hundredths: 45,
        disqualified: false
      }
    end

    context 'with valid attributes' do
      it 'is valid' do
        expect(subject).to be_valid
      end

      it 'can be saved' do
        expect { subject.save! }.not_to raise_error
      end
    end

    context 'validations' do
      it 'requires import_key' do
        subject.import_key = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:import_key]).to be_present
      end

      it 'requires unique import_key' do
        subject.save!
        duplicate = described_class.new(valid_attributes)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:import_key]).to include('has already been taken')
      end

      it 'requires import_key length <= 500' do
        subject.import_key = 'x' * 501
        expect(subject).not_to be_valid
      end

      it 'requires rank' do
        subject.rank = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:rank]).to be_present
      end

      it 'requires rank >= 0' do
        subject.rank = -1
        expect(subject).not_to be_valid
      end
    end

    describe '#to_timing' do
      it 'returns a Timing instance' do
        expect(subject.to_timing).to be_a(Timing)
      end

      it 'converts minutes, seconds, hundredths correctly' do
        subject.minutes = 1
        subject.seconds = 30
        subject.hundredths = 25
        expect(subject.to_timing.to_s).to eq("1'30\"25")
      end

      it 'handles zero values' do
        subject.minutes = 0
        subject.seconds = 0
        subject.hundredths = 0
        expect(subject.to_timing.to_s).to eq("0'00\"00")
      end
    end

    describe '#minimal_attributes' do
      before { subject.save! }

      it 'includes timing string' do
        attrs = subject.minimal_attributes
        expect(attrs).to have_key('timing')
        expect(attrs['timing']).to eq("0'58\"45")
      end

      it 'includes standard attributes' do
        attrs = subject.minimal_attributes
        expect(attrs).to have_key('id')
        expect(attrs).to have_key('import_key')
        expect(attrs).to have_key('rank')
      end
    end

    describe '.build_import_key' do
      it 'combines program_key and swimmer_key correctly' do
        program_key = '1-100SL-M45-M'
        swimmer_key = 'ROSSI-1978-M-CSI OBER FERRARI'
        expected = '1-100SL-M45-M/ROSSI-1978-M-CSI OBER FERRARI'

        result = described_class.build_import_key(program_key, swimmer_key)
        expect(result).to eq(expected)
      end

      it 'handles complex keys with special characters' do
        program_key = '2-200MI-F30-F'
        swimmer_key = "BIANCHI-D'ANGELO-1985-F-NUOTO CLUB FIRENZE"
        expected = "2-200MI-F30-F/BIANCHI-D'ANGELO-1985-F-NUOTO CLUB FIRENZE"

        result = described_class.build_import_key(program_key, swimmer_key)
        expect(result).to eq(expected)
      end
    end

    describe '.truncate!' do
      before do
        3.times do |i|
          described_class.create!(
            import_key: "test-key-#{i}",
            rank: i + 1,
            minutes: 0,
            seconds: 30 + i,
            hundredths: 0
          )
        end
      end

      it 'removes all records' do
        expect(described_class.count).to eq(3)
        described_class.truncate!
        expect(described_class.count).to eq(0)
      end
    end

    describe 'timestamps' do
      it 'sets created_at on save' do
        subject.save!
        expect(subject.created_at).to be_present
      end

      it 'sets updated_at on save' do
        subject.save!
        expect(subject.updated_at).to be_present
      end
    end

    describe 'indexes' do
      it 'has unique index on import_key' do
        subject.save!
        duplicate = described_class.new(valid_attributes)
        expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
