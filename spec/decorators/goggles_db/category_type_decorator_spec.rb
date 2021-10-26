# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::CategoryTypeDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::CategoryType.first(200).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::CategoryType).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the short_name' do
        expect(result).to include(fixture_row.short_name)
      end

      it 'includes the group_name' do
        expect(result).to include(fixture_row.group_name)
      end

      it 'includes the federation_type' do
        expect(result).to include(fixture_row.federation_type.short_name)
      end

      it 'includes the Season header_year' do
        expect(result).to include(fixture_row.season.header_year)
      end
    end
  end

  describe '#short_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the short_name' do
        expect(result).to include(fixture_row.short_name)
      end

      it 'includes the Season header_year' do
        expect(result).to include(fixture_row.season.header_year)
      end
    end
  end
end
