# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::SwimmingPoolDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::SwimmingPool.first(200).sample }
  let(:alternative_locale) { I18n.available_locales.reject { |code| code == I18n.locale }.first }

  before do
    expect(fixture_row).to be_a(GogglesDb::SwimmingPool).and be_valid
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

      it 'includes the nick_name' do
        expect(result).to include(fixture_row.nick_name)
      end

      it 'includes the pool type label' do
        expect(result).to include(fixture_row.pool_type.label)
      end

      it 'includes the city display label, when available' do
        expect(result).to include(fixture_row.city&.decorate&.display_label)
      end
    end

    context 'with an alternative locale & a valid row,' do
      subject(:result) { decorated_instance.display_label(alternative_locale) }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Pool type label' do
        expect(result).to include(fixture_row.pool_type.label(alternative_locale))
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

      it 'includes the pool type label' do
        expect(result).to include(fixture_row.pool_type.label)
      end

      it 'includes the city name, when available' do
        expect(result).to include(fixture_row.city&.name)
      end
    end

    context 'with an alternative locale & a valid row,' do
      subject(:result) { decorated_instance.short_label(alternative_locale) }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the Pool type label' do
        expect(result).to include(fixture_row.pool_type.label(alternative_locale))
      end
    end
  end
end
