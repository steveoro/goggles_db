# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

require 'wrappers/timing'

describe Timing, type: :model do
  let(:fix1_hundreds)  { (rand * 100).to_i % 100 }
  let(:fix1_secs)      { (rand * 60).to_i % 60 }
  let(:fix1_mins)      { (rand * 60).to_i % 60 }
  let(:fix1_hours)     { (rand * 24).to_i % 24 }
  let(:fix1_days)      { (rand * 3).to_i % 3 }

  shared_examples_for 'a valid Timing with all members at 0' do
    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(Timing)
    end
    it 'has 0 days'     do expect(subject.days).to eq(0); end
    it 'has 0 hours'    do expect(subject.hours).to eq(0); end
    it 'has 0 minutes'  do expect(subject.minutes).to eq(0); end
    it 'has 0 seconds'  do expect(subject.seconds).to eq(0); end
    it 'has 0 hundreds' do expect(subject.hundreds).to eq(0); end
  end

  shared_examples_for 'a valid Timing with all members assigned' do
    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(Timing)
    end
    it 'has 0 days'     do expect(subject.days).to eq(fix1_days); end
    it 'has 0 hours'    do expect(subject.hours).to eq(fix1_hours); end
    it 'has 0 minutes'  do expect(subject.minutes).to eq(fix1_mins); end
    it 'has 0 seconds'  do expect(subject.seconds).to eq(fix1_secs); end
    it 'has 0 hundreds' do expect(subject.hundreds).to eq(fix1_hundreds); end
  end
  #-- -------------------------------------------------------------------------
  #++

  context '[implemented methods]' do
    subject { Timing.new }

    it_behaves_like(
      'responding to a list of methods',
      %i[clear from_hundreds + - == <=> to_hundreds to_s]
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
      subject { Timing.new }
      it_behaves_like('a valid Timing with all members at 0')
    end

    context '[for an instance created with nil]' do
      subject { Timing.new(nil) }
      it_behaves_like('a valid Timing with all members at 0')
    end

    context '[for a non-zero instance]' do
      subject { Timing.new(fix1_hundreds, fix1_secs, fix1_mins, fix1_hours, fix1_days) }
      it_behaves_like('a valid Timing with all members assigned')
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe '#clear' do
    context '[for a non-zero instance]' do
      subject { Timing.new(fix1_hundreds, fix1_secs, fix1_mins, fix1_hours, fix1_days).clear }
      it_behaves_like('a valid Timing with all members at 0')
    end
  end

  describe '#from_hundreds' do
    let(:fixture_hundreds) { (rand * 10_000).to_i }
    subject { Timing.new.from_hundreds(fixture_hundreds) }

    it 'has an equal value of hundreds' do
      expect(subject.to_hundreds).to eq(fixture_hundreds)
    end
  end

  describe '#to_hundreds' do
    subject { Timing.new(fix1_hundreds, fix1_secs, fix1_mins, fix1_hours) }

    it 'returns a positive number' do
      expect(subject.to_hundreds).to be > 0
    end
    it 'has an equal value of hundreds' do
      expect(subject.to_hundreds).to eq(fix1_hours * 360_000 + fix1_mins * 6000 + fix1_secs * 100 + fix1_hundreds)
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe '#+' do
    let(:fixture_1) { Timing.new(rand * 100, rand * 60, rand * 60, rand * 24) }
    let(:fixture_2) { Timing.new(rand * 100, rand * 60, rand * 60, rand * 24) }
    subject { fixture_1 + fixture_2 }

    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(Timing)
    end
    it 'corresponds to the sum of the two objects in hundreds' do
      expect(subject.to_hundreds).to eq(fixture_1.to_hundreds + fixture_2.to_hundreds)
    end
  end

  describe '#-' do
    let(:fixture_1) { Timing.new(rand * 100, rand * 60, rand * 60, rand * 24) }
    let(:fixture_2) { Timing.new(rand * 100, rand * 60, rand * 60, rand * 24) }
    subject { fixture_1 - fixture_2 }

    it 'returns a Timing object' do
      expect(subject).to be_an_instance_of(Timing)
    end
    it 'corresponds to the sum of the two objects in hundreds' do
      expect(subject.to_hundreds).to eq(fixture_1.to_hundreds - fixture_2.to_hundreds)
    end
  end

  describe '#==' do
    let(:fixture_1)    { Timing.new(rand * 100, rand * 60, rand * 60, rand * 24) }
    let(:fixture_1_eq) { Timing.new(fixture_1.hundreds, fixture_1.seconds, fixture_1.minutes, fixture_1.hours) }
    let(:fixture_2)    { Timing.new(rand * 100, rand * 60, rand * 60, rand * 24) }
    let(:fixture_2_eq) { Timing.new(fixture_2.hundreds, fixture_2.seconds, fixture_2.minutes, fixture_2.hours) }

    it 'returns false for instances with different values' do
      expect(fixture_1 == fixture_2).to be false
    end
    it 'returns false for uncomparable objects' do
      expect(fixture_1 == 'asdfg').to be false
    end
    it 'returns true for instances with equal values' do
      expect(fixture_1 == fixture_1_eq).to be true
      expect(fixture_2 == fixture_2_eq).to be true
    end
  end

  describe '#<=>' do
    let(:fixture)       { Timing.new(rand * 100, rand * 60, rand * 60, rand * 24) }
    let(:fixture_eq)    { Timing.new(fixture.hundreds, fixture.seconds, fixture.minutes, fixture.hours) }
    let(:fixture_prev) do
      Timing.new(
        fixture.hundreds - rand * fixture.hundreds,
        fixture.seconds - rand * fixture.seconds,
        fixture.minutes - rand * fixture.minutes,
        fixture.hours
      )
    end
    let(:fixture_succ) do
      Timing.new(
        fixture.hundreds + rand * fixture.hundreds,
        fixture.seconds + rand * fixture.seconds,
        fixture.minutes + rand * fixture.minutes,
        fixture.hours
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
      expect(subject).to include(fix1_hundreds.to_s) if fix1_hundreds.to_i > 0
      expect(subject).to include(fix1_secs.to_s) if fix1_secs.to_i > 0
      expect(subject).to include(fix1_mins.to_s) if fix1_mins.to_i > 0
      expect(subject).to include(fix1_hours.to_s) if fix1_hours.to_i > 0
    end
  end

  describe '#to_s' do
    subject { Timing.new(fix1_hundreds, fix1_secs, fix1_mins, fix1_hours).to_s }
    it_behaves_like('the String result from a converted Timing instance')

    context 'with nil parameters,' do
      subject { Timing.to_s(nil, nil, nil) }
      it 'returns a String' do
        expect(subject).to be_an_instance_of(String)
      end
      it 'contains all zeros' do
        expect(subject).to include("0\' 0\"00")
      end
    end
  end

  describe 'self.to_s' do
    subject { Timing.to_s(fix1_hundreds, fix1_secs, fix1_mins, fix1_hours) }
    it_behaves_like('the String result from a converted Timing instance')

    context 'with nil parameters,' do
      subject { Timing.to_s(nil, nil, nil) }
      it 'returns a String' do
        expect(subject).to be_an_instance_of(String)
      end
      it 'contains all zeros' do
        expect(subject).to include("0\' 0\"00")
      end
    end
  end

  describe 'self.to_compact_s' do
    subject { Timing.to_compact_s(fix1_hundreds, fix1_secs, fix1_mins, fix1_hours) }
    it_behaves_like('the String result from a converted Timing instance')

    context 'with parameters having all 0 value,' do
      subject { Timing.to_compact_s(0, 0, 0, 0) }
      it 'returns an empty String' do
        expect(subject).to eq('')
      end
      it 'has the same result as no parameters' do
        expect(subject).to eq(Timing.to_compact_s)
      end
    end

    context 'with nil parameters,' do
      subject { Timing.to_compact_s(nil, nil, nil) }
      it 'returns an empty String' do
        expect(subject).to eq('')
      end
      it 'has the same result as no parameters' do
        expect(subject).to eq(Timing.to_compact_s)
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe 'self.to_hour_string' do
    context 'with a valid parameter,' do
      let(:fixture_secs) { rand * 600_000 }
      subject { Timing.to_hour_string(fixture_secs) }
      it 'returns a String' do
        expect(subject).to be_an_instance_of(String)
      end
      it "contains the 'hours' member when its value is > 0" do
        hours = fixture_secs.to_i / 3600
        expect(subject).to include("#{hours}h") if hours.positive?
      end
      it "contains the 'minutes' member when its value is > 0" do
        remainder = fixture_secs.to_i % 3600
        minutes = remainder / 60
        expect(subject).to include("#{minutes}'") if minutes.positive?
      end
      it "contains the 'seconds' member when its value is > 0" do
        remainder = fixture_secs.to_i % 3600
        seconds = remainder % 60
        expect(subject).to include("#{seconds}\"") if seconds.positive?
      end
    end

    context 'with a nil parameter,' do
      subject { Timing.to_hour_string(nil) }
      it 'returns an empty String' do
        expect(subject).to eq('')
      end
    end
  end

  describe 'self.to_minute_string' do
    context 'with a valid parameter,' do
      let(:fixture_secs) { rand * 3600 }
      subject { Timing.to_minute_string(fixture_secs) }
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
      subject { Timing.to_minute_string(nil) }
      it 'returns an empty String' do
        expect(subject).to eq('')
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  describe 'self.to_formatted_pause' do
    it 'returns a String' do
      expect(Timing.to_formatted_pause(rand * 360)).to be_an_instance_of(String)
    end
    it 'returns an empty String for a non-positive value' do
      expect(Timing.to_formatted_pause(0)).to   eq('')
      expect(Timing.to_formatted_pause(-1)).to  eq('')
      expect(Timing.to_formatted_pause(nil)).to eq('')
    end
  end

  describe 'self.to_formatted_start_and_rest' do
    it 'returns a String' do
      expect(Timing.to_formatted_start_and_rest(rand * 360)).to be_an_instance_of(String)
    end
    it 'returns an empty String for a non-positive value' do
      expect(Timing.to_formatted_start_and_rest(0)).to    eq('')
      expect(Timing.to_formatted_start_and_rest(-1)).to   eq('')
      expect(Timing.to_formatted_start_and_rest(nil)).to  eq('')
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
