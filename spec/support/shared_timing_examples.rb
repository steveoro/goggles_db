# frozen_string_literal: true

# subject = fixture_row.to_timing
shared_examples_for '#to_timing valid result' do
  it 'is a Timing instance' do
    expect(subject).to be_a(Timing)
  end
  it 'contains the same timing data than the original fixture' do
    expect(subject.hundreds).to eq(fixture_row.hundreds)
    expect(subject.seconds).to eq(fixture_row.seconds)
    expect(subject.minutes).to eq(fixture_row.minutes % 60)
    expect(subject.hours).to eq(60 * (fixture_row.minutes / 60))
    # (Don't care about days)
  end
end
