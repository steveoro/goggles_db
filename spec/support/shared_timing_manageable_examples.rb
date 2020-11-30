# frozen_string_literal: true

# subject = fixture_row.to_timing
shared_examples_for '#to_timing valid result' do
  it 'is a Timing instance' do
    expect(subject).to be_a(Timing).and be_present
  end
  it 'contains the same timing data than the original fixture' do
    expect(subject.hundreds).to eq(fixture_row.hundreds)
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
    it_behaves_like('responding to a list of methods', %i[hundreds seconds minutes to_timing])
  end

  describe '#to_timing' do
    subject { fixture_row.to_timing }
    it_behaves_like('#to_timing valid result')
  end
end
