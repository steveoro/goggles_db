# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_active_storage_examples'
require 'support/shared_application_record_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe Calendar do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:calendar) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      # Tests the validity of the default_scope when there's an optional association involved:
      it 'does not raise errors when selecting a random row with a field name' do
        field_name = %w[meeting_code scheduled_date season_id meeting_id].sample
        expect { described_class.unscoped.select(field_name).limit(100).sample }.not_to raise_error
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season]
      )
      it 'has a valid Season' do
        expect(subject.season).to be_a(Season).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[season meeting
           meeting_code scheduled_date meeting_name meeting_place
           year month
           manifest_code startlist_code results_code
           results_link startlist_link manifest_link
           manifest
           manifest_file manifest_file_contents
           results_file results_file_contents
           name_import_text organization_import_text
           place_import_text dates_import_text program_import_text
           read_only? expired?
           to_json]
      )

      # Presence of fields & required-ness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[meeting_code]
      )

      it_behaves_like('active storage field with local file', :manifest_file)
      it_behaves_like('active storage field with local file', :results_file)

      # Testing one is suffice enough (#results_file is equal):
      describe '#manifest_file_contents' do
        subject { fixture_row.manifest_file_contents }

        let(:fixture_row) { FactoryBot.create(:calendar_with_static_manifest_file) }

        it 'returns the string file contents' do
          expect(subject).to start_with('TEST Manifest for ')
        end
      end

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- -----------------------------------------------------------------------
    #++

    context 'when using the existing database domain,' do
      # Sorting scopes:
      describe 'self.by_meeting' do
        it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'meeting', 'header_date')
      end

      describe 'self.by_season' do
        it_behaves_like('sorting scope by_<ANY_ENTITY_NAME>', described_class, 'season', 'begin_date')
      end

      # Filtering scopes:
      describe 'self.not_cancelled' do
        it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER> with no parameters', described_class, 'not_cancelled',
                        'cancelled', false)
      end

      describe 'self.for_season_type' do
        it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season_type', 'season_type',
                        described_class.includes(:season_type).joins(:season_type).last(300).sample.season_type)
      end

      describe 'self.for_season' do
        it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_season', 'season',
                        described_class.includes(:meeting, :season).joins(:meeting, :season).last(300).sample.season)
      end

      describe 'self.for_code' do
        it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_code', 'meeting_code',
                        described_class.last(300).pluck(:meeting_code).uniq.sample)
      end

      describe 'self.still_open_at(date)' do
        context 'when there are Calendar rows having the scheduled_date set in the future,' do
          before do
            future_meetings = FactoryBot.create_list(:meeting, 5, header_date: Time.zone.today + 2.months)
            future_meetings.each { |meeting| FactoryBot.create(:calendar, meeting:) }
          end

          let(:result) { described_class.still_open_at.limit(10) } # (default params: Time.zone.today)

          it 'is a relation containing only Calendar rows having the either the meeting unset or with an header_date set in the future' do
            expect(result).to be_a(ActiveRecord::Relation)
            expect(result).to all be_a(described_class)
            all_calendar_meetings = result.filter_map(&:meeting).uniq
            expect(all_calendar_meetings.map(&:header_date)).to all be > Time.zone.today
          end
        end
      end
      #-- ---------------------------------------------------------------------
      #++

      describe '#expired?' do
        context 'when the calendar row has been cancelled,' do
          subject { FactoryBot.build(:calendar, cancelled: true) }

          it 'is true' do
            expect(subject.expired?).to be true
          end
        end

        context 'when the calendar row is not cancelled but has occurred in the past,' do
          subject do
            FactoryBot.build(
              :calendar,
              meeting: FactoryBot.build(:meeting, header_date: Time.zone.today - 1.day)
            )
          end

          it 'is true' do
            expect(subject.expired?).to be true
          end
        end

        context 'when the calendar row in not cancelled and is still open (up to the current date),' do
          subject do
            FactoryBot.build(
              :calendar,
              meeting: FactoryBot.build(:meeting, header_date: Time.zone.today)
            )
          end

          it 'is false' do
            expect(subject.expired?).to be false
          end
        end
      end
      #-- ---------------------------------------------------------------------
      #++

      describe '#minimal_attributes (override)' do
        subject(:result) { fixture_row.minimal_attributes }

        let(:fixture_row) { described_class.joins(:meeting).includes(:meeting).first(200).sample }

        %w[display_label short_label meeting_date].each do |method_name|
          it "includes the decorated '#{method_name}'" do
            expect(result[method_name]).to eq(fixture_row.decorate.send(method_name))
          end
        end
      end

      describe '#to_hash' do
        context 'for a row with an associated Meeting,' do
          subject { described_class.joins(:meeting).includes(:meeting).first(200).sample }
          # If we include the meeting above, we won't need to use the 'optional' version of the same example group:
          it_behaves_like(
            '#to_hash when the entity has any 1:1 required association with',
            %w[season season_type meeting]
          )
        end
      end
    end
  end
end
