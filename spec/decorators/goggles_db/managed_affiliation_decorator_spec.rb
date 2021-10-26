# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::ManagedAffiliationDecorator, type: :decorator do
  subject(:decorated_instance) { described_class.decorate(fixture_row) }

  let(:fixture_row) { GogglesDb::ManagedAffiliation.first(200).sample }

  before do
    expect(fixture_row).to be_a(GogglesDb::ManagedAffiliation).and be_valid
    expect(decorated_instance).to be_a(described_class).and be_valid
  end

  describe '#display_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.display_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the manager label' do
        expect(result).to include(fixture_row.manager.decorate.display_label)
      end

      it 'includes the Team affiliation label' do
        expect(result).to include(fixture_row.team_affiliation.decorate.short_label)
      end
    end
  end

  describe '#short_label' do
    context 'with a valid row,' do
      subject(:result) { decorated_instance.short_label }

      it 'is a non-empty String' do
        expect(result).to be_a(String).and be_present
      end

      it 'includes the manager short label' do
        expect(result).to include(fixture_row.manager.decorate.short_label)
      end

      it 'includes the Team affiliation label' do
        expect(result).to include(fixture_row.team_affiliation.decorate.short_label)
      end
    end
  end
end
