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

    context 'with a seasonal edition type,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.seasonal) }

      it 'returns the label as a numeric string' do
        expect(subject.edition_label).to eq("#{subject.edition}°")
      end
    end

    context 'with a yearly edition type,' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.yearly) }

      it 'returns the first part of the header_year as label' do
        expect(subject.edition_label).to eq(subject.header_year.to_s.split('/')&.first)
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
        'Long static name with no edition', 'Trofeo SuperMaster Città di Riccione', 'Meeting Master Torino',
        ' Città del Tricolore, Reggio Emilia'
      ].each do |fixture_name|
        it 'is the base name returned by the normalizer/splitter, uncondensed but stripped' do
          expected_result = GogglesDb::Normalizers::CodedName.edition_split_from(fixture_name).second
          expect(subject.name_without_edition(fixture_name)).to eq(expected_result.strip)
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
        'Meeting Fake short name', 'Trofeo Città di Riccione', 'Master Torino',
        'Città di Reggio Emilia'
      ].each do |base_name|
        it "is just the base name without the edition label (name: '#{base_name}')" do
          if subject.edition_label.present?
            expect(
              subject.name_without_edition("#{subject.edition_label} #{base_name}")
            ).to eq(base_name)
          end
        end
      end
    end

    context 'with a custom name parameter that includes an edition label at the end (YEARLY),' do
      subject { FactoryBot.build(factory_name_sym, edition_type: GogglesDb::EditionType.yearly) }

      [
        'Meeting Fake short name', 'Trofeo Città di Riccione', 'Meeting Master Torino',
        'Trofeo Città di Reggio Emilia'
      ].each do |base_name|
        it "is just the base name without the edition label (name: '#{base_name}')" do
          # DEBUG
          # puts "\r\ned.label: '#{subject.edition_label}'"
          if subject.edition_label.present?
            expect(
              subject.name_without_edition("#{base_name} #{subject.edition_label}")
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

# REQUIRES/ASSUMES:
# (none)
shared_examples_for 'AbstractMeeting #expired?' do |factory_name_sym|
  describe 'for a valid instance' do
    context 'when the meeting is cancelled,' do
      subject { FactoryBot.build(factory_name_sym, cancelled: true) }

      it 'is true' do
        expect(subject.expired?).to be true
      end
    end

    context 'when the meeting is not cancelled but has occurred in the past,' do
      subject { FactoryBot.build(factory_name_sym, header_date: Time.zone.today - 1.day) }

      it 'is true' do
        expect(subject.expired?).to be true
      end
    end

    context 'when the meeting is not cancelled and is still open (up to the current date),' do
      subject { FactoryBot.build(factory_name_sym, header_date: Time.zone.today) }

      it 'is false' do
        expect(subject.expired?).to be false
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

# REQUIRES/ASSUMES:
# - the existance of some fixture rows
shared_examples_for 'AbstractMeeting sorting & filtering scopes' do |factory_name_sym|
  # Sorting scopes:
  describe 'self.by_date' do
    it_behaves_like('sorting scope by_<ANY_VALUE_NAME>', described_class, 'date', 'header_date')
  end

  describe 'self.by_season' do
    it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'begin_date')
  end

  # Filtering scopes:
  describe 'self.not_cancelled' do
    it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER> with no parameters', described_class, 'not_cancelled',
                    'cancelled', false)
  end

  describe 'self.not_expired' do
    context 'when there are uncancelled meetings having the header_date set in the future,' do
      before { FactoryBot.create_list(factory_name_sym, 3, header_date: Time.zone.today + 2.months) }

      let(:result) { described_class.not_expired.limit(10) }

      it 'is a relation containing only uncancelled meetings (having the header_date set in the future)' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(described_class)
        expect(
          result.map(&:header_date).uniq
        ).to all be >= Time.zone.today
        expect(result.map(&:cancelled).uniq).to all be false
      end
    end
  end

  describe 'self.for_season_type' do
    it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season_type',
                    'season_type', GogglesDb::SeasonType.all_masters.sample)
  end

  describe 'self.for_code' do
    it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_code', 'code',
                    %w[csiprova1 csiprova2 italiani europei regemilia riccione].sample)
  end
end
#-- ---------------------------------------------------------------------------
#++
