# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::CityDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::City.first(100).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::City).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the name' do
        expect(result).to include(fixture_row.name)
      end

      it 'includes the area' do
        expect(result).to include(fixture_row.area)
      end

      it 'includes the country_code' do
        expect(result).to include(fixture_row.country_code)
      end
    end
  end

  describe '#short_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the name' do
        expect(result).to include(fixture_row.name)
      end

      it 'includes the area' do
        expect(result).to include(fixture_row.area)
      end
    end
  end
end
