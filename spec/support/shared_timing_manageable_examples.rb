# frozen_string_literal: true

# subject = fixture_row.to_timing
shared_examples_for '#to_timing valid result' do |from_start|
  it 'is a Timing instance' do
    # to_timing may also return a zero when the instance is not filled, so no presence check here:
    expect(subject).to be_a(Timing)
  end

  it 'contains the same timing data than the original fixture' do
    if from_start && fixture_row.respond_to?(:hundredths_from_start)
      expect(subject.hundredths).to eq(fixture_row.hundredths_from_start.to_i)
      expect(subject.seconds).to eq(fixture_row.seconds_from_start.to_i)
      expect(subject.minutes).to eq(fixture_row.minutes_from_start.to_i % 60)
      expect(subject.hours).to eq(60 * (fixture_row.minutes_from_start.to_i / 60))
      # (Don't care about days)
    else
      expect(subject.hundredths).to eq(fixture_row.hundredths.to_i)
      expect(subject.seconds).to eq(fixture_row.seconds.to_i)
      expect(subject.minutes).to eq(fixture_row.minutes.to_i % 60)
      expect(subject.hours).to eq(60 * (fixture_row.minutes.to_i / 60))
      # (Don't care about days)
    end
  end
end

# subject = fixture_row
shared_examples_for 'TimingManageable' do
  # Describes the requistes of the including class and the outcome of the module inclusion:
  context 'by including this concern, the sibling:' do
    subject { fixture_row }

    it_behaves_like('responding to a list of methods', %i[hundredths seconds minutes to_timing from_timing positive? zero?])
  end

  context 'for any result with positive time,' do
    subject do
      # Make sure the fixture_row has at least a column with positive time:
      fixture_row.seconds = 1
      fixture_row
    end

    describe '#positive?' do
      it 'is true' do
        expect(subject.positive?).to be true
      end
    end

    describe '#present?' do
      it 'is always true' do
        expect(subject.present?).to be true
      end
    end

    describe '#zero?' do
      it 'is false' do
        expect(subject.zero?).to be false
      end
    end
  end

  context 'for any result with zero time,' do
    subject do
      # Make sure the fixture_row has all columns with zero time:
      fixture_row.hundredths = 0
      fixture_row.seconds = 0
      fixture_row.minutes = 0
      if fixture_row.respond_to?(:hundredths_from_start=)
        fixture_row.hundredths_from_start = 0
        fixture_row.seconds_from_start = 0
        fixture_row.minutes_from_start = 0
      end
      fixture_row
    end

    describe '#positive?' do
      it 'is false' do
        expect(subject.positive?).to be false
      end
    end

    describe '#present?' do
      it 'is always true' do
        expect(subject.present?).to be true
      end
    end

    describe '#zero?' do
      it 'is true' do
        expect(subject.zero?).to be true
      end
    end
  end

  context 'a new instance with zero timing' do
    subject { described_class.new }

    it 'is always #present?, even if #zero? is true' do
      expect(subject.zero?).to be true
      expect(subject.present?).to be true
    end
  end
  #-- ------------------------------------------------------------------------
  #++

  describe '#to_timing' do
    context 'when from_start is false (default),' do
      subject { fixture_row.to_timing }

      it_behaves_like('#to_timing valid result', false)
    end

    context 'when from_start is true,' do
      subject { fixture_row.to_timing(from_start: true) }

      it_behaves_like('#to_timing valid result', true)
    end
  end

  describe '#from_timing' do
    let(:new_hundredths) { ((rand * 100) % 99).to_i }
    let(:new_seconds) { ((rand * 100) % 59).to_i }
    let(:new_minutes) { ((rand * 100) % 59).to_i }
    let(:new_hours) { ((rand * 100) % 24).to_i }
    let(:new_days) { ((rand * 100) % 5).to_i }
    let(:new_timing) { Timing.new(hundredths: new_hundredths, seconds: new_seconds, minutes: new_minutes, hours: new_hours, days: new_days) }

    context 'when from_start is false (default),' do
      subject { fixture_row.from_timing(new_timing) }

      it 'returns self' do
        expect(subject).to eq(fixture_row)
      end

      it 'sets the internal time members with the data from the fixture' do
        expect(subject.hundredths).to eq(new_hundredths)
        expect(subject.seconds).to eq(new_seconds)
        expect(subject.minutes).to eq(new_minutes)
        # Skip the higher order checks if the original fixture_row doesn't support them:
        expect(subject.hours).to eq(new_hours) if fixture_row.respond_to?(:hours=)
        expect(subject.days).to eq(new_days) if fixture_row.respond_to?(:days=)
      end
    end

    context 'when from_start is true,' do
      subject { fixture_row.from_timing(new_timing, from_start: true) }

      it 'returns self' do
        expect(subject).to eq(fixture_row)
      end

      it 'sets the internal \'XXX_from_start\' time members with the data from the fixture (when these columns are supported)' do
        if fixture_row.respond_to?(:hundredths_from_start)
          expect(subject.hundredths_from_start).to eq(new_hundredths)
          expect(subject.seconds_from_start).to eq(new_seconds)
          expect(subject.minutes_from_start).to eq(new_minutes)
          # Skip the higher order checks if the original fixture_row doesn't support them:
          expect(subject.hours_from_start).to eq(new_hours) if fixture_row.respond_to?(:hours_from_start=)
          expect(subject.days_from_start).to eq(new_days) if fixture_row.respond_to?(:days_from_start=)
        end
      end
    end
  end
end
