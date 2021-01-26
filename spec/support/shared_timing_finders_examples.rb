# frozen_string_literal: true

# === Requires:
#
# - +subject+     => #search_by result called on any sibling of TimingFinders::BaseStrategy
# - +fixture_mir+ => the reference MIR for the event (can be any one of the Swimmer's MIRs)
#
shared_examples_for 'a TimingFinder strategy #search_by that can select a MIR with a non-zero timing value' do
  it 'is a MIR' do
    expect(subject).to be_an(GogglesDb::MeetingIndividualResult)
  end

  it 'selects a coherent MIR' do
    expect(subject.event_type.id).to eq(fixture_mir.event_type.id)
  end

  it 'has a positive timing' do
    expect(subject.to_timing.to_hundredths).to be_positive
  end
end

# === Requires:
#
# - +subject+ => #search_by result called on any sibling of TimingFinders::BaseStrategy
#
shared_examples_for 'a TimingFinder strategy #search_by that cannot find any related MIR row' do
  it 'is a MIR anyway (empty)' do
    expect(subject).to be_an(GogglesDb::MeetingIndividualResult)
  end

  it 'has zeroed Timing' do
    expect(subject.to_timing).to eq(Timing.new)
  end
end
