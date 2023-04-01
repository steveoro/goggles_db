# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

shared_examples_for 'AbstractLap sorting scopes' do |sibling_class|
  describe 'self.by_distance' do
    it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', sibling_class, 'distance', 'length_in_meters')
  end
end
#-- ---------------------------------------------------------------------------
#++

# REQUIRES/ASSUMES:
# - result.........: the actual subject to be tested
# - existing_row...: fixture instance of the sibling class used, with a valid
#                    parent association. (MIR => Lap, UserResult => UserLap)
shared_examples_for 'filtering scope for the same group of laps' do |sibling_class|
  before { expect(existing_row).to be_a(sibling_class).and be_valid }

  it 'is a relation containing only laps belonging to the same parent result' do
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to all be_a(sibling_class)
    parent_result_id = existing_row.send(sibling_class.parent_result_column_sym)
    expect(result.map { |row| row.send(sibling_class.parent_result_column_sym) }.uniq)
      .to all eq(parent_result_id)
  end

  it 'has a positive number of items' do
    expect(result.count).to be_positive
  end

  it 'includes the specified Lap' do
    expect(result.pluck(:id).uniq).to include(existing_row.id)
  end
end

# REQUIRES/ASSUMES:
# - existing_row...: fixture instance of the sibling class used, with a valid
#                    parent association. (MIR => Lap, UserResult => UserLap)
shared_examples_for 'AbstractLap filtering scopes' do |sibling_class|
  describe 'self.with_time' do
    it_behaves_like('filtering scope with_time', sibling_class)
  end

  describe 'self.with_no_time' do
    it_behaves_like('filtering scope with_no_time', sibling_class)
  end

  describe 'self.related_laps' do
    context 'given a Lap with a valid parent result association,' do
      let(:result) { sibling_class.related_laps(existing_row) }

      it_behaves_like('filtering scope for the same group of laps', sibling_class)
    end
  end

  describe 'self.summing_laps' do
    context 'given a lap with a valid parent result association,' do
      let(:result) { sibling_class.summing_laps(existing_row) }

      it_behaves_like('filtering scope for the same group of laps', sibling_class)

      it 'contains only preceding laps plus the current one' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(sibling_class)
        expect(result.pluck(:length_in_meters)).to all be <= existing_row.length_in_meters
      end
    end
  end

  describe 'self.following_laps' do
    context 'given a lap with a valid parent result association,' do
      let(:result) { sibling_class.following_laps(existing_row) }

      it 'is a relation containing only laps belonging to the same parent result' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(sibling_class)
        parent_result_id = existing_row.send(sibling_class.parent_result_column_sym)
        expect(result.map { |row| row.send(sibling_class.parent_result_column_sym) }.uniq)
          .to all eq(parent_result_id)
      end

      it 'has a positive number of items' do
        expect(result.count).to be_positive
      end

      it 'does NOT includes the specified Lap' do
        expect(result.pluck(:id).uniq).not_to include(existing_row.id)
      end

      it 'contains only following laps having length greater than the current one' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(sibling_class)
        expect(result.pluck(:length_in_meters)).to all be > existing_row.length_in_meters
      end
    end
  end
end
#-- ---------------------------------------------------------------------------
#++

# REQUIRES/ASSUMES:
# - fixture_row...: a valid fixture instance of the sibling class
# - the existance of some rows with the timing from start values zeroed out
shared_examples_for 'AbstractLap #timing_from_start' do |sibling_class|
  describe '#timing_from_start' do
    context 'with an instance having the "_from_start" values,' do
      subject { fixture_row.timing_from_start }

      before do
        amount = fixture_row.minutes_from_start.to_i +
                 fixture_row.hundredths_from_start.to_i +
                 fixture_row.seconds_from_start.to_i
        expect(amount).to be_positive
      end

      it 'returns the Timing instance computed using the "_from_start" values' do
        expect(subject).to eq(
          Timing.new(
            hundredths: fixture_row.hundredths_from_start,
            seconds: fixture_row.seconds_from_start,
            minutes: fixture_row.minutes_from_start
          )
        )
      end
    end

    context 'with an instance without the "_from_start" values,' do
      subject { existing_row.timing_from_start }

      let(:existing_row) do
        sibling_class.where(hundredths_from_start: 0, seconds_from_start: 0, minutes_from_start: 0)
                     .first(100)
                     .sample
      end

      before do
        expect(existing_row).to be_a(sibling_class).and be_valid
        expect(existing_row.seconds_from_start).to be_zero
      end

      it 'computes the correct Timing instance using all involved previous laps' do
        involved_laps = sibling_class.summing_laps(existing_row)
        expect(subject).to eq(
          Timing.new(
            hundredths: involved_laps.sum(:hundredths),
            seconds: involved_laps.sum(:seconds),
            minutes: involved_laps.sum(:minutes)
          )
        )
      end
    end
  end
end
#-- ---------------------------------------------------------------------------
#++

# REQUIRES/ASSUMES:
# - fixture_row...: a valid fixture instance of the sibling class
shared_examples_for 'AbstractLap #minimal_attributes' do
  subject { fixture_row.minimal_attributes }

  it 'is an Hash' do
    expect(subject).to be_an(Hash)
  end

  %w[gender_type].each do |association_name|
    it "includes the #{association_name} association key" do
      expect(subject.keys).to include(association_name)
    end
  end
  it 'includes the timing string' do
    expect(subject['timing']).to eq(fixture_row.to_timing.to_s)
  end

  it 'includes the timing string from the start of the race' do
    expect(subject['timing_from_start']).to eq(fixture_row.timing_from_start.to_s)
  end

  it "contains the 'synthetized' swimmer details" do
    expect(subject['swimmer']).to be_an(Hash).and be_present
    expect(subject['swimmer']).to eq(fixture_row.swimmer_attributes)
  end
end
#-- ---------------------------------------------------------------------------
#++
