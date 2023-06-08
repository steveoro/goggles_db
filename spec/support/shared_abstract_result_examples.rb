# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'

# REQUIRES/ASSUMES:
# - subject...: a valid fixture instance of the sibling class
# - the existance of some rows having set disqualified & out_of_race both true & false
shared_examples_for 'AbstractResult filtering scopes' do |sibling_class|
  describe 'self.qualifications' do
    let(:result) { subject.class.qualifications.order('disqualified DESC').limit(20) }

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
# - the existance of some fixture rows
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
