# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::SwimmerDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::Swimmer.first(200).sample }
  let(:alternative_locale) { I18n.available_locales.reject { |code| code == I18n.locale }.first }

  before do
    expect(fixture_row).to be_a(GogglesDb::Swimmer).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the complete name' do
        expect(result).to include(fixture_row.complete_name)
      end

      it 'includes the gender type label' do
        expect(result).to include(fixture_row.gender_type.label)
      end

      it 'includes the year of birth' do
        expect(result).to include(fixture_row.year_of_birth.to_s)
      end
    end

    context 'with a row that is missing the gender type,' do
      subject(:result) do
        new_row = GogglesDb::Swimmer.new
        # Makes new no defaults are set for the gender_type:
        new_row.gender_type = nil
        described_class.decorate(new_row).display_label
      end

      it 'does not raise an error and is a non-empty String' do
        expect { result }.not_to raise_error
        expect(result).to be_a(String).and be_present
      end
    end

    context 'with an alternative locale & a valid row,' do
      subject(:result) { decorated_instance.display_label(alternative_locale) }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the gender type label' do
        expect(result).to include(fixture_row.gender_type.label(alternative_locale))
      end
    end
  end

  describe '#short_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the complete name' do
        expect(result).to include(fixture_row.complete_name)
      end

      it 'includes the year of birth' do
        expect(result).to include(fixture_row.year_of_birth.to_s)
      end
    end
  end
end
