# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'

module GogglesDb
  RSpec.describe AppParameter do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:app_parameter) }

      it 'is valid' do
        expect(subject).to be_valid
      end

      # (This tests the class methods using an instance, so this is the right context:)
      it_behaves_like(
        'responding to a list of class methods',
        %i[versioning_row maintenance? maintenance=]
      )

      it 'responds to #maintenance? (which is off by default)' do
        expect(subject).to respond_to(:maintenance?)
        # Default value for factory constructor:
        expect(subject.maintenance?).to be false
      end

      it_behaves_like('ApplicationRecord shared interface')
    end

    describe 'self.versioning_row' do
      subject { described_class.versioning_row }

      it 'is an instance of AppParameter' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it 'has a non-empty string for DB versioning' do
        expect(subject.send(described_class::DB_VERSION_FIELDNAME)).to be_present
      end

      it 'has a non-empty string for full App versioning' do
        expect(subject.send(described_class::FULL_VERSION_FIELDNAME)).to be_present
      end

      it 'has the maintenance mode flag toggled off' do
        expect(subject.maintenance?).to be false
      end
    end

    describe 'self.maintenance=' do
      it 'changes the value of the maintenance toggle switch' do
        # Make sure default value is correct before testing the method:
        expect(described_class.maintenance?).to be false
        expect { described_class.maintenance = true }.to change(described_class, :maintenance?).to true
      end
    end

    describe 'self.config' do
      subject { described_class.config }

      it 'is an instance of AppParameter' do
        expect(subject).to be_a(described_class).and be_valid
      end

      described_class::SETTINGS_GROUPS.each do |setting_key|
        it "includes the :#{setting_key} settings key" do
          expect(subject.settings(setting_key)).to be_a(RailsSettings::SettingObject)
          expect(subject.settings(setting_key).value).to be_an(Hash)
        end
      end
    end

    describe 'self.max_anonymous_req' do
      it 'returns the configured value from the :app settings group' do
        row = described_class.versioning_row
        row.settings(:app).max_anonymous_req = 750
        row.save!
        expect(described_class.max_anonymous_req).to eq(750)
      end

      it 'falls back to the default when the setting is missing' do
        row = described_class.versioning_row
        row.settings(:app).max_anonymous_req = nil
        row.save!
        expect(described_class.max_anonymous_req).to eq(described_class::DEFAULT_MAX_ANONYMOUS_REQ)
      end
    end
  end
end
