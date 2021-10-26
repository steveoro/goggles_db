# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::TeamAffiliationDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::TeamAffiliation.first(200).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::TeamAffiliation).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Season display label' do
        expect(result).to include(fixture_row.season.decorate.display_label)
      end

      it 'includes the Team display label' do
        expect(result).to include(fixture_row.team.decorate.display_label)
      end
    end
  end

  describe '#short_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Season short label' do
        expect(result).to include(fixture_row.season.decorate.short_label)
      end

      it 'includes the affiliation name' do
        expect(result).to include(fixture_row.name)
      end
    end
  end
end
