# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

# REQUIRES/ASSUMES:
# (none)
shared_examples_for 'AbstractMeeting #edition_label' do |factory_name_sym|
  describe 'for a valid instance' do
    context 'with an ordinal edition type,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.ordinal) }

      it 'returns the label as a numeric string' do
        expect(subject.edition_label).to eq("#{subject.edition}°")
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
# (none)
shared_examples_for 'AbstractMeeting #name_without_edition' do |factory_name_sym|
  describe 'for a valid instance' do
    context 'with the default description parameter,' do
      subject do
        FactoryBot.build(
          factory_name_sym,
          edition_type: GogglesDb::EditionType.send(%i[ordinal roman none yearly seasonal].sample)
        )
      end

      it 'does not include the edition_label' do
        expect(subject.name_without_edition).not_to include(subject.edition_label.to_s) if subject.edition_label.present?
      end

      it 'does not include the header_year' do
        expect(subject.name_without_edition).not_to include(subject.header_year.to_s)
      end
    end

    context 'with a custom name parameter that does not include any edition label,' do
      subject do
        FactoryBot.build(
          factory_name_sym,
          edition_type: GogglesDb::EditionType.send(%i[ordinal roman none yearly seasonal].sample)
        )
      end

      [
        'Long static name with no edition', 'Città di Riccione', 'Master Torino',
        'Città di Reggio Emilia'
      ].each do |fixture_name|
        it 'is the same custom name but shortened if it is too long' do
          expect(subject.name_without_edition(fixture_name))
            .to eq(
              fixture_name.split(/\s|,/)
                          .reject(&:empty?)[0..3]
                          .join(' ')
            )
        end
      end
    end

    context 'with a custom name parameter that includes an edition label at the front,' do
      subject do
        FactoryBot.build(
          factory_name_sym,
          edition_type: GogglesDb::EditionType.send(%i[ordinal roman].sample)
        )
      end

      [
        'Fake short name', 'Città di Riccione', 'Master Torino',
        'Città di Reggio Emilia'
      ].each do |base_name|
        it "is just the base name without the edition label (base name: '#{base_name}')" do
          if subject.edition_label.present?
            expect(
              subject.name_without_edition("#{subject.edition_label} Trofeo #{base_name}")
            ).to eq(base_name)
          end
        end
      end
    end

    context 'with a custom name parameter that includes an edition label at the end,' do
      subject do
        FactoryBot.build(
          factory_name_sym,
          edition_type: GogglesDb::EditionType.send(%i[yearly seasonal].sample)
        )
      end

      [
        'Fake short name', 'Città di Riccione', 'Master Torino',
        'Città di Reggio Emilia'
      ].each do |base_name|
        it "is just the base name without the edition label (base name: '#{base_name}')" do
          if subject.edition_label.present?
            expect(
              subject.name_without_edition("Trofeo #{base_name} #{subject.edition_label}")
            ).to eq(base_name)
          end
        end
      end
    end
  end
end

# REQUIRES/ASSUMES:
# (none)
shared_examples_for 'AbstractMeeting #name_with_edition' do |factory_name_sym|
  describe 'for a valid instance' do
    context 'with ordinal or roman edition type (prefix),' do
      subject do
        FactoryBot.build(
          factory_name_sym,
          edition_type: GogglesDb::EditionType.send(%i[ordinal roman].sample)
        )
      end

      it 'includes the edition_label' do
        expect(subject.name_with_edition).to include(subject.edition_label.to_s)
      end

      it 'includes the base name without its edition (if already present in the description)' do
        expect(subject.name_with_edition).to include(subject.name_without_edition.to_s)
      end
    end

    context 'with seasonal or yearly edition type (postfix),' do
      subject do
        FactoryBot.build(
          factory_name_sym,
          edition_type: GogglesDb::EditionType.send(%i[seasonal yearly].sample)
        )
      end

      it 'includes the header_year' do
        expect(subject.name_with_edition).to include(subject.header_year.to_s)
      end

      it 'includes the base name without its edition (if already present in the description)' do
        expect(subject.name_with_edition).to include(subject.name_without_edition.to_s)
      end
    end

    context 'with no edition type set,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.none) }

      it 'is the default meeting name' do
        expect(subject.name_with_edition).to eq(subject.description)
      end
    end
  end
end

# REQUIRES/ASSUMES:
# (none)
shared_examples_for 'AbstractMeeting #condensed_name' do |factory_name_sym|
  describe 'for a valid instance' do
    context 'with a description that includes a common prefix,' do
      subject do
        FactoryBot.build(
          factory_name_sym,
          description: "#{common_prefix} #{base_tokens.join(' ')}"
        )
      end

      let(:common_prefix) { %w[Trofeo Meeting Collegiale Workshop Campionato Raduno].sample }
      let(:base_tokens) { FFaker::Lorem.words(6) }

      it 'does not include the common prefix' do
        expect(subject.condensed_name).not_to include(common_prefix)
      end

      it 'reduces the name to just the last 4 base tokens of the name' do
        expect(subject.condensed_name).to eq(base_tokens.first(4).join(' '))
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

  it 'includes the display_label (from the decorator)' do
    expect(subject['display_label']).to eq(fixture_row.decorate.display_label)
  end

  it 'includes the short_label (from the decorator)' do
    expect(subject['short_label']).to eq(fixture_row.decorate.short_label)
  end

  it 'includes the edition_label' do
    expect(subject['edition_label']).to eq(fixture_row.edition_label.to_s)
  end

  %w[season edition_type timing_type season_type federation_type].each do |member_name|
    it "includes the #{member_name} association key" do
      # Don't check nil association links: (it may happen)
      expect(subject.keys).to include(member_name) if fixture_row.send(member_name).present?
    end
  end
end
#-- ---------------------------------------------------------------------------
#++
