# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

require 'wrappers/timing'

describe Timing, type: :model do
  let(:fix1_hundredths)  { (rand * 100).to_i % 100 }
  let(:fix1_secs)      { (rand * 60).to_i % 60 }
  let(:fix1_mins)      { (rand * 60).to_i % 60 }
  let(:fix1_hours)     { (rand * 24).to_i % 24 }
  let(:fix1_days)      { (rand * 3).to_i % 3 }

  shared_examples_for 'a valid Timing with all members at 0' do
    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(described_class)
    end

    it 'has 0 days'     do expect(subject.days).to eq(0); end
    it 'has 0 hours'    do expect(subject.hours).to eq(0); end
    it 'has 0 minutes'  do expect(subject.minutes).to eq(0); end
    it 'has 0 seconds'  do expect(subject.seconds).to eq(0); end
    it 'has 0 hundredths' do expect(subject.hundredths).to eq(0); end

    describe '#zero?' do
      it 'is true' do
        expect(subject.zero?).to be true
      end
    end

    describe '#empty?' do
      it 'is true' do
        expect(subject.empty?).to be true
      end
    end

    describe '#positive?' do
      it 'is false' do
        expect(subject.positive?).to be false
      end
    end

    describe '#negative?' do
      it 'is false' do
        expect(subject.negative?).to be false
      end
    end
  end

  shared_examples_for 'a valid Timing with all members assigned' do
    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(described_class)
    end

    it 'has 0 days'     do expect(subject.days).to eq(fix1_days); end
    it 'has 0 hours'    do expect(subject.hours).to eq(fix1_hours); end
    it 'has 0 minutes'  do expect(subject.minutes).to eq(fix1_mins); end
    it 'has 0 seconds'  do expect(subject.seconds).to eq(fix1_secs); end
    it 'has 0 hundredths' do expect(subject.hundredths).to eq(fix1_hundredths); end

    describe '#zero?' do
      it 'is false' do
        expect(subject.zero?).to be false
      end
    end

    describe '#empty?' do
      it 'is false' do
        expect(subject.empty?).to be false
      end
    end

    describe '#positive?' do
      it 'is true' do
        expect(subject.positive?).to be true
      end
    end

    describe '#negative?' do
      it 'is false' do
        expect(subject.negative?).to be false
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  context '[implemented methods]' do
    subject { described_class.new }

    it_behaves_like(
      'responding to a list of methods',
      %i[clear from_hundredths + - * == <=> to_hundredths zero? positive? negative? empty? to_s to_compact_s]
    )
    it_behaves_like(
      'responding to a list of class methods',
      %i[to_s to_compact_s to_hour_string to_minute_string to_formatted_pause to_formatted_start_and_rest]
    )
  end
  #-- -------------------------------------------------------------------------
  #++

  describe '#initialize' do
    context '[for an empty instance]' do
      subject { described_class.new }

      it_behaves_like('a valid Timing with all members at 0')
    end

    context '[for an instance created with nil]' do
      subject { described_class.new(nil) }

      it_behaves_like('a valid Timing with all members at 0')
    end

    context '[for a non-zero instance]' do
      subject { described_class.new(hundredths: fix1_hundredths, seconds: fix1_secs, minutes: fix1_mins, hours: fix1_hours, days: fix1_days) }

      it_behaves_like('a valid Timing with all members assigned')
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe '#clear' do
    context '[for a non-zero instance]' do
      subject { described_class.new(hundredths: fix1_hundredths, seconds: fix1_secs, minutes: fix1_mins, hours: fix1_hours, days: fix1_days).clear }

      it_behaves_like('a valid Timing with all members at 0')
    end
  end

  describe '#from_hundredths' do
    subject { described_class.new.from_hundredths(fixture_hundredths) }

    let(:fixture_hundredths) { (rand * 10_000).to_i }

    it 'has an equal value of hundredths' do
      expect(subject.to_hundredths).to eq(fixture_hundredths)
    end
  end

  describe '#to_hundredths' do
    subject { described_class.new(hundredths: fix1_hundredths, seconds: fix1_secs, minutes: fix1_mins, hours: fix1_hours) }

    it 'returns a positive number' do
      expect(subject.to_hundredths).to be > 0
    end

    it 'has an equal value of hundredths' do
      expect(subject.to_hundredths).to eq((fix1_hours * 360_000) + (fix1_mins * 6000) + (fix1_secs * 100) + fix1_hundredths)
    end
  end

  describe '#zero? / #empty?' do
    let(:fixture) { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }

    it 'is false for a non-zero timing' do
      expect(fixture.zero?).to be false
      expect(fixture.empty?).to be false
    end

    it 'is true for a zeroed timing' do
      expect(described_class.new.zero?).to be true
      expect(described_class.new.empty?).to be true
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe '#+' do
    subject { fixture_a + fixture_b }

    let(:fixture_a) { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }
    let(:fixture_b) { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }

    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(described_class)
    end

    it 'corresponds to the sum of the two objects in hundredths' do
      expect(subject.to_hundredths).to eq(fixture_a.to_hundredths + fixture_b.to_hundredths)
    end
  end

  describe '#-' do
    subject { fixture_a - fixture_b }

    let(:fixture_a) { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }
    let(:fixture_b) { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }

    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(described_class)
    end

    it 'corresponds to the sum of the two objects in hundredths' do
      expect(subject.to_hundredths).to eq(fixture_a.to_hundredths - fixture_b.to_hundredths)
    end
  end

  describe '#*' do
    subject { fixture_a * int_number }

    let(:fixture_a) { described_class.new(hundredths: rand * 100, seconds: 1 + (rand * 60), minutes: rand * 60, hours: rand * 24) }
    let(:int_number) { (1 + (rand * 100)).to_i }

    it 'raises an ArgumentError when no valid integer value is specified' do
      expect { fixture_a * [nil, 'not-a-number', 2.5].sample }.to raise_error(ArgumentError)
    end

    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(described_class)
    end

    it 'is the value in hundredths multiplied by the numeric value' do
      expect(subject.to_hundredths).to eq(fixture_a.to_hundredths * int_number)
    end
  end

  describe '#==' do
    let(:fixture_a)    { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }
    let(:fixture_a_eq) { described_class.new(hundredths: fixture_a.hundredths, seconds: fixture_a.seconds, minutes: fixture_a.minutes, hours: fixture_a.hours) }
    let(:fixture_b)    { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }
    let(:fixture_b_eq) { described_class.new(hundredths: fixture_b.hundredths, seconds: fixture_b.seconds, minutes: fixture_b.minutes, hours: fixture_b.hours) }

    it 'returns false for instances with different values' do
      expect(fixture_a == fixture_b).to be false
    end

    it 'returns false for uncomparable objects' do
      expect(fixture_a == 'asdfg').to be false
    end

    it 'returns true for instances with equal values' do
      expect(fixture_a == fixture_a_eq).to be true
      expect(fixture_b == fixture_b_eq).to be true
    end
  end

  describe '#<=>' do
    let(:fixture)       { described_class.new(hundredths: rand * 100, seconds: rand * 60, minutes: rand * 60, hours: rand * 24) }
    let(:fixture_eq)    { described_class.new(hundredths: fixture.hundredths, seconds: fixture.seconds, minutes: fixture.minutes, hours: fixture.hours) }
    let(:fixture_prev) do
      described_class.new(
        hundredths: fixture.hundredths - (rand * fixture.hundredths),
        seconds: fixture.seconds - (rand * fixture.seconds),
        minutes: fixture.minutes - (rand * fixture.minutes),
        hours: fixture.hours
      )
    end
    let(:fixture_succ) do
      described_class.new(
        hundredths: fixture.hundredths + (rand * fixture.hundredths),
        seconds: fixture.seconds + (rand * fixture.seconds),
        minutes: fixture.minutes + (rand * fixture.minutes),
        hours: fixture.hours
      )
    end

    it 'returns 0 for instances with equal values' do
      expect(fixture <=> fixture_eq).to eq(0)
    end

    it 'returns -1 when the instances is lesser than the argument' do
      expect(fixture <=> fixture_succ).to eq(-1)
    end

    it 'returns 1 when the instances is greater than the argument' do
      expect(fixture <=> fixture_prev).to eq(1)
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  shared_examples_for 'the String result from a converted Timing instance' do
    it 'returns a String' do
      expect(subject).to be_an_instance_of(String)
    end

    it 'includes the value of its most significant and non-zero members' do
      expect(subject).to include(fix1_hundredths.to_s) if fix1_hundredths.to_i > 0
      expect(subject).to include(fix1_secs.to_s) if fix1_secs.to_i > 0
      expect(subject).to include(fix1_mins.to_s) if fix1_mins.to_i > 0
      expect(subject).to include(fix1_hours.to_s) if fix1_hours.to_i > 0
    end
  end

  describe '#to_s' do
    subject { described_class.new(hundredths: fix1_hundredths, seconds: fix1_secs, minutes: fix1_mins, hours: fix1_hours).to_s }

    it_behaves_like('the String result from a converted Timing instance')

    context 'with nil parameters,' do
      subject { described_class.to_s(hundredths: nil, seconds: nil, minutes: nil) }

      it 'returns a String' do
        expect(subject).to be_an_instance_of(String)
      end

      it 'contains all zeros' do
        expect(subject).to match("0'00\"00")
      end
    end
  end

  describe 'self.to_s' do
    subject { described_class.to_s(hundredths: fix1_hundredths, seconds: fix1_secs, minutes: fix1_mins, hours: fix1_hours) }

    it_behaves_like('the String result from a converted Timing instance')

    context 'with nil parameters,' do
      subject { described_class.to_s(hundredths: nil, seconds: nil, minutes: nil) }

      it 'returns a String' do
        expect(subject).to be_an_instance_of(String)
      end

      it 'contains all zeros' do
        expect(subject).to eq("0'00\"00")
      end
    end
  end

  describe 'self.to_compact_s' do
    subject { described_class.to_compact_s(hundredths: fix1_hundredths, seconds: fix1_secs, minutes: fix1_mins, hours: fix1_hours) }

    it_behaves_like('the String result from a converted Timing instance')

    context 'with parameters having all 0 value,' do
      subject { described_class.to_compact_s(hundredths: 0, seconds: 0, minutes: 0, hours: 0) }

      it 'returns an empty String' do
        expect(subject).to eq('')
      end

      it 'has the same result as no parameters' do
        expect(subject).to eq(described_class.to_compact_s)
      end
    end

    context 'with nil parameters,' do
      subject { described_class.to_compact_s(hundredths: nil, seconds: nil, minutes: nil) }

      it 'returns an empty String' do
        expect(subject).to eq('')
      end

      it 'has the same result as no parameters' do
        expect(subject).to eq(described_class.to_compact_s)
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe 'self.to_hour_string' do
    context 'with a valid parameter,' do
      subject { described_class.to_hour_string(fixture_secs) }

      let(:fixture_secs) { rand * 600_000 }
      let(:actual_timing) { described_class.new(seconds: fixture_secs) }

      before { expect(actual_timing).to be_a(described_class) }

      it 'returns a String' do
        expect(subject).to be_an_instance_of(String)
      end

      it "contains the 'hours' member when its value is > 0" do
        expect(subject).to include("#{actual_timing.hours}h") if actual_timing.hours.positive?
      end

      it "contains the 'minutes' member when its value is > 0" do
        expect(subject).to include("#{actual_timing.minutes}'") if actual_timing.minutes.positive?
      end

      it "contains the 'seconds' member when its value is > 0" do
        expect(subject).to include("#{actual_timing.seconds}\"") if actual_timing.seconds.positive?
      end
    end

    context 'with a nil parameter,' do
      subject { described_class.to_hour_string(nil) }

      it 'returns an empty String' do
        expect(subject).to eq('')
      end
    end
  end

  describe 'self.to_minute_string' do
    context 'with a valid parameter,' do
      subject { described_class.to_minute_string(fixture_secs) }

      let(:fixture_secs) { rand * 3600 }

      it 'returns a String' do
        expect(subject).to be_an_instance_of(String)
      end

      it "does not contain the 'hours' member, even if its value is > 0" do
        hours = fixture_secs.to_i / 3600
        expect(subject).not_to include("#{hours}h") if hours.positive?
      end

      it "contains the 'minutes' member when its value is > 0" do
        minutes = fixture_secs.to_i / 60
        expect(subject).to include("#{minutes}'") if minutes.positive?
      end

      it "contains the 'seconds' member when its value is > 0" do
        seconds = fixture_secs.to_i % 60
        expect(subject).to include("#{seconds}\"") if seconds.positive?
      end
    end

    context 'with a nil parameter,' do
      subject { described_class.to_minute_string(nil) }

      it 'returns an empty String' do
        expect(subject).to eq('')
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe 'self.to_formatted_pause' do
    it 'returns a String' do
      expect(described_class.to_formatted_pause(rand * 360)).to be_an_instance_of(String)
    end

    it 'returns an empty String for a non-positive value' do
      expect(described_class.to_formatted_pause(0)).to   eq('')
      expect(described_class.to_formatted_pause(-1)).to  eq('')
      expect(described_class.to_formatted_pause(nil)).to eq('')
    end
  end

  describe 'self.to_formatted_start_and_rest' do
    it 'returns a String' do
      expect(described_class.to_formatted_start_and_rest(rand * 360)).to be_an_instance_of(String)
    end

    it 'returns an empty String for a non-positive value' do
      expect(described_class.to_formatted_start_and_rest(0)).to    eq('')
      expect(described_class.to_formatted_start_and_rest(-1)).to   eq('')
      expect(described_class.to_formatted_start_and_rest(nil)).to  eq('')
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
