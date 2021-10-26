# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::UserDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::User.first(100).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::User).and be_valid
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

      it 'includes the email' do
        expect(result).to include(fixture_row.email)
      end

      it 'includes the description' do
        expect(result).to include(fixture_row.description)
      end

      it 'includes the year of birth' do
        expect(result).to include(fixture_row.year_of_birth.to_s)
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

      it 'includes the description' do
        expect(result).to include(fixture_row.description)
      end
    end
  end
end
