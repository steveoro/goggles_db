# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_method_existance_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_to_json_examples'
require 'support/shared_active_storage_examples'

module GogglesDb
  RSpec.describe Calendar, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:calendar) }

      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
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
           read_only?
           to_json]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[meeting_code]
      )

      it_behaves_like('active storage field with local file', :manifest_file)
      it_behaves_like('active storage field with local file', :results_file)

      # Testing one is suffice enough (#results_file is equal):
      describe '#manifest_file_contents' do
        subject { fixture_row.manifest_file_contents }

        let(:fixture_row) { FactoryBot.create(:calendar_with_manifest_file) }

        # After each test, make sure the attachments are removed (see above factory def):
        after { fixture_row.manifest_file.purge }

        it 'returns the string file contents' do
          expect(subject).to start_with('TEST Manifest for ')
        end
      end
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
            future_meetings.each { |meeting| FactoryBot.create(:calendar, meeting: meeting) }
          end

          let(:result) { described_class.still_open_at.limit(10) } # (default params: Time.zone.today)

          it 'is a relation containing only Calendar rows having the either the meeting unset or with an header_date set in the future' do
            expect(result).to be_a(ActiveRecord::Relation)
            expect(result).to all be_a(described_class)
            all_calendar_meetings = result.map(&:meeting).compact.uniq
            expect(all_calendar_meetings.map(&:header_date)).to all be > Time.zone.today
          end
        end
      end
      #-- ------------------------------------------------------------------------
      #++

      describe '#to_json' do
        context 'for a row with an associated Meeting,' do
          # subject { FactoryBot.create(:calendar) }
          subject { described_class.joins(:meeting).includes(:meeting).first(200).sample }

          it_behaves_like(
            '#to_json when called on a valid instance',
            %w[season]
          )
        end

        context 'for a row without an associated Meeting,' do
          subject do
            result = described_class.where(meeting_id: nil).first(100).sample
            result = FactoryBot.create(:calendar_with_blank_meeting) if result.blank?
            expect(result).to be_present
            expect(result.meeting).to be_blank
            result
          end

          it_behaves_like(
            '#to_json when called with unset optional associations',
            %w[meeting]
          )
        end
      end
    end
  end
end
