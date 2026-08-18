# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe JsonRow do
    subject(:json_row) { described_class.new(attributes) }

    let(:attributes) do
      {
        'id' => 101, 'length_in_meters' => 50,
        'minutes' => 0, 'seconds' => 31, 'hundredths' => 25,
        'minutes_from_start' => 1, 'seconds_from_start' => 2, 'hundredths_from_start' => 50
      }
    end

    it 'defines a reader for each source key' do
      expect(json_row.id).to eq(101)
      expect(json_row.length_in_meters).to eq(50)
      expect(json_row.seconds).to eq(31)
    end

    it 'accepts symbol keys too' do
      expect(described_class.new(id: 7).id).to eq(7)
    end

    it 'supports the TimingManageable helpers' do
      expect(json_row.to_timing).to eq(Timing.new(minutes: 0, seconds: 31, hundredths: 25))
      expect(json_row.timing_from_start).to eq(Timing.new(minutes: 1, seconds: 2, hundredths: 50))
      expect(json_row).to be_positive
    end

    it 'supports equality by attributes' do
      expect(json_row).to eq(described_class.new(attributes))
      expect(json_row).not_to eq(described_class.new(attributes.merge('id' => 999)))
    end
  end
end
