# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe DataImportMeetingRelayResult do
    subject { FactoryBot.build(:data_import_meeting_relay_result) }

    let(:valid_attributes) do
      FactoryBot.attributes_for(:data_import_meeting_relay_result)
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
        duplicate = described_class.new(subject.attributes.except('id', 'created_at', 'updated_at'))
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
        timing = Timing.new(
          hundredths: subject.hundredths,
          seconds: subject.seconds,
          minutes: subject.minutes
        )
        expect(subject.to_timing.to_s).to eq(timing.to_s)
      end
    end

    describe '#minimal_attributes' do
      before { subject.save! }

      it 'includes timing string' do
        attrs = subject.minimal_attributes
        expect(attrs).to have_key('timing')
        expect(attrs['timing']).to eq(subject.to_timing.to_s)
      end

      it 'includes relay_code' do
        attrs = subject.minimal_attributes
        expect(attrs).to have_key('relay_code')
        expect(attrs['relay_code']).to eq(subject.relay_code)
      end

      it 'handles nil relay_code' do
        subject.relay_code = nil
        attrs = subject.minimal_attributes
        expect(attrs['relay_code']).to eq('')
      end
    end

    describe '.build_import_key' do
      it 'combines program_key, team_key, and timing correctly' do
        program_key = '1-4X50SL-M160-M'
        team_key = 'CSI OBER FERRARI'
        timing = '01:45.67'
        expected = '1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67'

        result = described_class.build_import_key(program_key, team_key, timing)
        expect(result).to eq(expected)
      end

      it 'handles nil timing' do
        program_key = '1-4X50SL-M160-M'
        team_key = 'CSI OBER FERRARI'
        expected = '1-4X50SL-M160-M/CSI OBER FERRARI-0'

        result = described_class.build_import_key(program_key, team_key, nil)
        expect(result).to eq(expected)
      end
    end

    describe 'associations' do
      describe 'data_import_relay_laps' do
        it 'has many data_import_relay_laps' do
          expect(subject).to respond_to(:data_import_relay_laps)
        end

        it 'uses composite key relationship' do
          subject.save!

          lap1 = FactoryBot.create(
            :data_import_relay_lap,
            parent_import_key: subject.import_key,
            import_key: "#{subject.import_key}/50",
            length_in_meters: 50,
            phase_file_path: subject.phase_file_path
          )

          lap2 = FactoryBot.create(
            :data_import_relay_lap,
            parent_import_key: subject.import_key,
            import_key: "#{subject.import_key}/100",
            length_in_meters: 100,
            phase_file_path: subject.phase_file_path
          )

          expect(subject.data_import_relay_laps).to contain_exactly(lap1, lap2)
        end

        it 'deletes laps when parent is destroyed' do
          subject.save!

          lap = FactoryBot.create(
            :data_import_relay_lap,
            parent_import_key: subject.import_key,
            import_key: "#{subject.import_key}/50",
            length_in_meters: 50,
            phase_file_path: subject.phase_file_path
          )

          expect { subject.destroy }.to change(DataImportRelayLap, :count).by(-1)
          expect(DataImportRelayLap.find_by(id: lap.id)).to be_nil
        end
      end

      describe 'data_import_meeting_relay_swimmers' do
        it 'has many data_import_meeting_relay_swimmers' do
          expect(subject).to respond_to(:data_import_meeting_relay_swimmers)
        end

        it 'uses composite key relationship' do
          subject.save!

          swimmer1 = FactoryBot.create(
            :data_import_meeting_relay_swimmer,
            parent_import_key: subject.import_key,
            import_key: "mrs1-#{subject.import_key}-ROSSI-1978-M-CSI",
            relay_order: 1,
            phase_file_path: subject.phase_file_path
          )

          swimmer2 = FactoryBot.create(
            :data_import_meeting_relay_swimmer,
            parent_import_key: subject.import_key,
            import_key: "mrs2-#{subject.import_key}-BIANCHI-1980-M-CSI",
            relay_order: 2,
            phase_file_path: subject.phase_file_path
          )

          expect(subject.data_import_meeting_relay_swimmers).to contain_exactly(swimmer1, swimmer2)
        end

        it 'deletes swimmers when parent is destroyed' do
          subject.save!

          swimmer = FactoryBot.create(
            :data_import_meeting_relay_swimmer,
            parent_import_key: subject.import_key,
            import_key: "mrs1-#{subject.import_key}-ROSSI-1978-M-CSI",
            relay_order: 1,
            phase_file_path: subject.phase_file_path
          )

          expect { subject.destroy }.to change(DataImportMeetingRelaySwimmer, :count).by(-1)
          expect(DataImportMeetingRelaySwimmer.find_by(id: swimmer.id)).to be_nil
        end
      end
    end
  end
end
