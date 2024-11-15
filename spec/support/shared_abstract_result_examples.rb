# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

# (no REQUIRES)
shared_examples_for 'AbstractResult sorting scopes' do
  describe 'delegated methods (used by the sorting scopes)' do
    subject { described_class.first(50).sample }

    it_behaves_like(
      'responding to a list of methods',
      %i[swimmer_first_name swimmer_last_name swimmer_complete_name
         swimmer_year_of_birth swimmer_gender_type_id present? positive? zero?]
    )
  end

  describe 'self.by_rank' do
    let(:result) { described_class.by_rank.limit(20) }

    it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'rank')
  end

  describe 'self.by_timing' do
    let(:result) { described_class.by_timing.limit(20) }

    it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'to_timing')
  end

  describe 'self.by_swimmer' do
    let(:result) { described_class.by_swimmer.limit(20) }

    it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'swimmer_complete_name')
  end
end

# REQUIRES/ASSUMES:
# - subject: a valid fixture instance of the sibling class
# - the existence of some rows having set disqualified & out_of_race both true & false
shared_examples_for 'AbstractResult filtering scopes' do |sibling_class|
  describe 'self.qualifications' do
    let(:result) { subject.class.qualifications.limit(20).order('disqualified DESC').limit(20) }

    it 'contains only qualified results' do
      expect(result.map(&:disqualified?).uniq).to all(be false)
    end
  end

  describe 'self.disqualifications' do
    let(:result) { subject.class.disqualifications.limit(20) }

    it 'contains only qualified results' do
      expect(result).to all(be_disqualified)
    end
  end

  describe 'self.for_pool_type' do
    it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', sibling_class, 'pool_type')
  end

  describe 'self.for_event_type' do
    it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', sibling_class, 'event_type')
  end

  describe 'self.for_gender_type' do
    it_behaves_like(
      'filtering scope for_<ANY_CHOSEN_FILTER>',
      sibling_class,
      'for_gender_type',
      'gender_type',
      GogglesDb::GenderType.send(%w[male female].sample)
    )
  end

  describe 'self.for_swimmer' do
    it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', sibling_class, 'swimmer')
  end

  describe 'self.for_rank' do
    it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', sibling_class, 'for_rank', 'rank', (1..10).to_a.sample)
  end

  describe 'self.with_rank' do
    it_behaves_like('filtering scope with_rank', sibling_class)
  end

  describe 'self.with_no_rank' do
    it_behaves_like('filtering scope with_no_rank', sibling_class)
  end

  describe 'self.with_time' do
    it_behaves_like('filtering scope with_time', sibling_class)
  end

  describe 'self.with_no_time' do
    it_behaves_like('filtering scope with_no_time', sibling_class)
  end
end
#-- ---------------------------------------------------------------------------
#++

# REQUIRES/ASSUMES:
# - the existence of some fixture rows
shared_examples_for 'AbstractResult #minimal_attributes' do |sibling_class, _min_associations_list|
  subject { fixture_row.minimal_attributes }

  let(:fixture_row) { sibling_class.last(100).sample }
  before { expect(fixture_row).to be_a(sibling_class).and be_valid }

  it 'includes the timing string' do
    expect(subject['timing']).to eq(fixture_row.to_timing.to_s)
  end

  it 'includes the swimmer name & decorated label' do
    expect(subject['swimmer_name']).to eq(fixture_row.swimmer.complete_name)
    expect(subject['swimmer_label']).to eq(fixture_row.swimmer.decorate.display_label)
  end
end
#-- ---------------------------------------------------------------------------
#++
