# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_sorting_scopes_examples'

module GogglesDb
  RSpec.describe Training do
    let(:image_path) { GogglesDb::Engine.root.join('spec', 'fixtures', 'files', 'test_creative_training.jpg') }

    # During tests, objects are wrapped in a transaction so destroy is never called upon them and
    # their corresponding data folder for the blobs stays there even after purging the attachable.
    after { FileUtils.rm_rf(Rails.root.join('tmp/storage')) }

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:training) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it 'has a title auto-composed as "<iso_date> <created_by>"' do
        expect(subject.title).to start_with(subject.training_date.to_date.iso8601)
          .and include(subject.created_by)
      end

      it_behaves_like 'ApplicationRecord shared interface'

      it_behaves_like 'responding to a list of methods',
                      %i[picture picture_filename picture_available?]
    end

    context 'with a factory-built row with attached picture' do
      subject { FactoryBot.create(:training_with_picture) }

      it 'has an attached picture' do
        expect(subject.picture).to be_attached
      end

      it 'exposes the original filename via #picture_filename' do
        expect(subject.picture_filename).to eq('test_creative_training.jpg')
      end

      it 'reports the picture as available on the storage service' do
        expect(subject.picture_available?).to be true
      end
    end

    context 'when required fields are missing' do
      it 'is not valid without training_by' do
        expect(FactoryBot.build(:training, training_by: nil)).not_to be_valid
      end

      it 'is not valid without created_by' do
        expect(FactoryBot.build(:training, created_by: nil)).not_to be_valid
      end

      it 'is not valid without training_date' do
        expect(FactoryBot.build(:training, training_date: nil)).not_to be_valid
      end
    end

    context 'when two rows share the same date & created_by' do
      let!(:first) do
        FactoryBot.create(:training, training_date: '2026-01-15', created_by: 'Test Author')
      end
      let!(:second) do
        FactoryBot.create(:training, training_date: '2026-01-15', created_by: 'Test Author')
      end

      it 'dedupes the auto-built title with a suffix' do
        expect(first.title).to eq('2026-01-15 Test Author')
        expect(second.title).to eq('2026-01-15 Test Author #2')
      end
    end

    context 'when an invalid picture content type is attached' do
      subject { FactoryBot.build(:training) }

      before do
        subject.picture.attach(
          io: File.open(GogglesDb::Engine.root.join('spec', 'fixtures', 'test-script.sql')),
          filename: 'test-script.sql', content_type: 'application/sql'
        )
      end

      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'when a swimmer is set' do
      let(:swimmer) { FactoryBot.create(:swimmer) }

      subject { FactoryBot.create(:training, swimmer:) }

      it 'is valid and linked' do
        expect(subject).to be_valid
        expect(subject.swimmer).to eq(swimmer)
      end
    end

    describe 'self.by_date' do
      before { Prosopite.pause { FactoryBot.create_list(:training, 5) } }

      # (The fixture DB contains legacy rows with NULL training_date: exclude them from the check)
      let(:result) { described_class.by_date.where.not(training_date: nil) }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'training_date')
    end
  end
end
