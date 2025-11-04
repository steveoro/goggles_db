# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe DataImportMeetingRelaySwimmer do
    subject { FactoryBot.build(:data_import_meeting_relay_swimmer, :first_fraction) }

    let(:parent_key) { subject.parent_import_key }
    let(:valid_attributes) do
      FactoryBot.attributes_for(:data_import_meeting_relay_swimmer, :first_fraction)
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
      end

      it 'requires unique import_key' do
        subject.save!
        duplicate = described_class.new(subject.attributes.except('id', 'created_at', 'updated_at'))
        expect(duplicate).not_to be_valid
      end

      it 'requires parent_import_key' do
        subject.parent_import_key = nil
        expect(subject).not_to be_valid
      end

      it 'requires relay_order' do
        subject.relay_order = nil
        expect(subject).not_to be_valid
      end

      it 'requires relay_order >= 1' do
        subject.relay_order = 0
        expect(subject).not_to be_valid
      end

      it 'requires relay_order <= 4' do
        subject.relay_order = 5
        expect(subject).not_to be_valid
      end
    end

    describe '#to_timing' do
      it 'returns a Timing instance' do
        expect(subject.to_timing).to be_a(Timing)
      end

      it 'converts timing correctly' do
        timing = Timing.new(
          hundredths: subject.hundredths,
          seconds: subject.seconds,
          minutes: subject.minutes
        )
        expect(subject.to_timing.to_s).to eq(timing.to_s)
      end
    end

    describe '.build_import_key' do
      it 'combines order, MRR key, and swimmer key correctly' do
        order = 1
        mrr_key = '1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67'
        swimmer_key = 'ROSSI-1978-M-CSI OBER FERRARI'
        expected = 'mrs1-1-4X50SL-M160-M/CSI OBER FERRARI-01:45.67-ROSSI-1978-M-CSI OBER FERRARI'

        result = described_class.build_import_key(order, mrr_key, swimmer_key)
        expect(result).to eq(expected)
      end

      it 'handles different relay orders' do
        mrr_key = '1-4X50SL-M160-M/CSI-01:45.67'
        swimmer_key = 'ROSSI-1978-M-CSI'

        result1 = described_class.build_import_key(1, mrr_key, swimmer_key)
        result2 = described_class.build_import_key(2, mrr_key, swimmer_key)
        result3 = described_class.build_import_key(3, mrr_key, swimmer_key)
        result4 = described_class.build_import_key(4, mrr_key, swimmer_key)

        expect(result1).to start_with('mrs1-')
        expect(result2).to start_with('mrs2-')
        expect(result3).to start_with('mrs3-')
        expect(result4).to start_with('mrs4-')
      end
    end

    describe 'associations' do
      describe 'data_import_meeting_relay_result' do
        it 'belongs to data_import_meeting_relay_result' do
          expect(subject).to respond_to(:data_import_meeting_relay_result)
        end

        it 'can access parent via composite key' do
          parent = FactoryBot.create(
            :data_import_meeting_relay_result,
            import_key: parent_key
          )

          subject.save!
          expect(subject.data_import_meeting_relay_result).to eq(parent)
        end

        it 'allows optional parent (orphaned swimmers)' do
          subject.parent_import_key = 'nonexistent-key'
          subject.save!
          expect(subject.data_import_meeting_relay_result).to be_nil
        end
      end
    end
  end
end
