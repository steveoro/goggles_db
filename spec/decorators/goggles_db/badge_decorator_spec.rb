# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::BadgeDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::Badge.first(200).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::Badge).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Season label' do
        expect(result).to include(fixture_row.season.decorate.display_label)
      end

      it 'includes the Swimmer label' do
        expect(result).to include(fixture_row.swimmer.decorate.display_label)
      end

      it 'includes the Team label' do
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

      it 'includes the Swimmer short label' do
        expect(result).to include(fixture_row.swimmer.decorate.short_label)
      end

      it 'includes the Team short label' do
        expect(result).to include(fixture_row.team.decorate.short_label)
      end
    end
  end
end
