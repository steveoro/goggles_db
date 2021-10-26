# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::TeamDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::Team.first(200).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::Team).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the editable name' do
        expect(result).to include(fixture_row.editable_name)
      end

      it 'includes the City display label, when available' do
        expect(result).to include(fixture_row.city&.decorate&.display_label) if fixture_row.city.present?
      end
    end
  end

  describe '#short_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the editable name' do
        expect(result).to include(fixture_row.editable_name)
      end

      it 'includes the City name, when available' do
        expect(result).to include(fixture_row.city&.name) if fixture_row.city.present?
      end
    end
  end
end
