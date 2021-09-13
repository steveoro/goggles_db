# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

# REQUIRES/ASSUMES:
# - the existance of some fixture rows
shared_examples_for 'AbstractMeeting #edition_label' do |factory_name_sym|
  describe 'for a valid instance' do
    context 'with an ordinal edition type,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.ordinal) }

      it 'returns the label as a numeric string' do
        expect(subject.edition_label).to eq(subject.edition.to_s)
      end
    end

    context 'with a roman edition type,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.roman) }

      it 'returns the label as a roman numeral' do
        expect(subject.edition_label).to eq(subject.edition.to_i.to_roman)
      end
    end

    context 'with a seasonal or yearly edition type,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.send(%w[yearly seasonal].sample)) }

      it 'returns the header_year as label' do
        expect(subject.edition_label).to eq(subject.header_year)
      end
    end

    context 'with an unspecified edition type,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.none) }

      it 'returns an empty string label' do
        expect(subject.edition_label).to eq('')
      end
    end
  end
end
#-- ---------------------------------------------------------------------------
#++

# REQUIRES/ASSUMES:
# - the existance of some fixture rows
shared_examples_for 'AbstractMeeting #minimal_attributes' do |sibling_class|
  subject { fixture_row.minimal_attributes }

  let(:fixture_row) { sibling_class.limit(100).sample }
  before { expect(fixture_row).to be_a(sibling_class).and be_valid }

  it 'is an Hash' do
    expect(subject).to be_an(Hash)
  end

  it 'includes the edition_label' do
    expect(subject['edition_label']).to eq(fixture_row.edition_label.to_s)
  end

  %w[edition_label season edition_type timing_type season_type federation_type].each do |member_name|
    it "includes the #{member_name} association key" do
      # Don't check nil association links: (it may happen)
      expect(subject.keys).to include(member_name) if fixture_row.send(member_name).present?
    end
  end
end
#-- ---------------------------------------------------------------------------
#++
