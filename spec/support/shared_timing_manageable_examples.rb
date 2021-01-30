# frozen_string_literal: true

# subject = fixture_row.to_timing
shared_examples_for '#to_timing valid result' do
  it 'is a Timing instance' do
    expect(subject).to be_a(Timing).and be_present
  end
  it 'contains the same timing data than the original fixture' do
    expect(subject.hundredths).to eq(fixture_row.hundredths)
    expect(subject.seconds).to eq(fixture_row.seconds)
    expect(subject.minutes).to eq(fixture_row.minutes % 60)
    expect(subject.hours).to eq(60 * (fixture_row.minutes / 60))
    # (Don't care about days)
  end
end

# subject = fixture_row
shared_examples_for 'TimingManageable' do
  # Describes the requistes of the including class and the outcome of the module inclusion:
  context 'by including this concern, the sibling:' do
    subject { fixture_row }
    it_behaves_like('responding to a list of methods', %i[hundredths seconds minutes to_timing from_timing])
  end

  describe '#to_timing' do
    subject { fixture_row.to_timing }
    it_behaves_like('#to_timing valid result')
  end

  describe '#from_timing' do
    let(:new_hundredths) { ((rand * 100) % 99).to_i }
    let(:new_seconds) { ((rand * 100) % 59).to_i }
    let(:new_minutes) { ((rand * 100) % 59).to_i }
    let(:new_hours) { ((rand * 100) % 24).to_i }
    let(:new_days) { ((rand * 100) % 5).to_i }
    let(:new_timing) { Timing.new(hundredths: new_hundredths, seconds: new_seconds, minutes: new_minutes, hours: new_hours, days: new_days) }
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
end
