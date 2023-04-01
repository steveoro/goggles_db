# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::ImportQueueDecorator, type: :decorator do
  let(:fixture_event_type) { GogglesDb::EventType.all.sample }
  let(:minutes) { (rand * 5).to_i }
  let(:seconds) { (rand * 59).to_i }
  let(:hundredths) { (rand * 99).to_i }
  let(:meters) { 50 + ((rand * 8).to_i * 50) }
  let(:timing_request_data) do
    {
      'target_entity' => 'Lap',
      'lap' => {
        'swimmer' => { 'complete_name' => fixture_swimmer.complete_name },
        'meeting_individual_result' => {
          'event_type_id' => fixture_event_type.id
        },
        'length_in_meters' => meters,
        'minutes' => minutes,
        'seconds' => seconds,
        'hundredths' => hundredths
      }
    }.to_json
  end
  let(:fixture_swimmer) { FactoryBot.build(:swimmer) }
  #-- -------------------------------------------------------------------------
  #++

  before do
    expect(fixture_swimmer).to be_a(GogglesDb::Swimmer)
    expect(fixture_event_type).to be_a(GogglesDb::EventType).and be_valid
    expect(timing_request_data).to be_a(String).and be_present
  end

  describe '#state_flag' do
    context 'with a row which is done (but not yet deleted),' do
      subject { described_class.decorate(model_obj) }

      let(:model_obj) { FactoryBot.create(:import_queue, done: true) }

      it 'returns a green dot' do
        expect(subject.state_flag).to eq('🟢')
      end
    end

    context "for a row which hasn't been processed yet," do
      subject { described_class.decorate(model_obj) }

      let(:model_obj) { FactoryBot.create(:import_queue) }

      it 'returns an empty string' do
        expect(subject.state_flag).to be_a(String).and be_empty
      end
    end

    context 'with a row that has already been processed at least once,' do
      subject { described_class.decorate(model_obj) }

      let(:model_obj) { FactoryBot.create(:import_queue, process_runs: 1) }

      it 'returns the counter of runs' do
        expect(subject.state_flag).to eq('▶ 1')
      end
    end
  end

  context 'with a row that contains a valid master chrono timing req,' do
    subject { described_class.decorate(fixture_row) }

    let(:fixture_row) { FactoryBot.create(:import_queue, uid: 'chrono', request_data: timing_request_data) }

    describe '#chrono_result_label' do
      it 'includes a chrono icon' do
        expect(subject.chrono_result_label).to include('⏱')
      end

      it 'includes the final result timing' do
        expect(subject.chrono_result_label).to include(ERB::Util.html_escape(fixture_row.req_final_timing.to_s))
      end

      it 'includes the event type' do
        expect(subject.chrono_result_label).to include(fixture_row.req_event_type&.label)
      end

      it 'includes the swimmer name' do
        expect(subject.chrono_result_label).to include(ERB::Util.html_escape(fixture_row.req_swimmer_name))
      end
    end

    describe '#chrono_delta_label' do
      it 'is empty' do
        expect(subject.chrono_delta_label).to be_empty
      end
    end

    describe '#text_label' do
      it 'is aliased with #display_label && #short_label' do
        expect(subject.text_label).to eq(subject.display_label)
        expect(subject.text_label).to eq(subject.short_label)
      end

      it 'equals the chrono_result_label' do
        expect(subject.text_label).to eq(subject.chrono_result_label)
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  context 'with a row that contains a valid sibling chrono timing req,' do
    subject { described_class.decorate(fixture_row) }

    let(:fixture_row) { FactoryBot.create(:import_queue, uid: 'chrono-1', request_data: timing_request_data) }

    describe '#chrono_result_label' do
      it 'is empty' do
        expect(subject.chrono_result_label).to be_empty
      end
    end

    describe '#chrono_delta_label' do
      it 'includes a delta-t icon' do
        expect(subject.chrono_delta_label).to include('Δt')
      end

      it 'includes the overall lap timing' do
        expect(subject.chrono_delta_label).to include(ERB::Util.html_escape(fixture_row.req_timing.to_s))
      end

      it 'includes the length in meters' do
        expect(subject.chrono_delta_label).to include(fixture_row.req_length_in_meters.to_s)
      end

      it 'includes the delta timing when available (laps > 0)' do
        if fixture_row.req_delta_timing.positive?
          expect(subject.chrono_delta_label)
            .to include(ERB::Util.html_escape(fixture_row.req_delta_timing.to_s))
        end
      end
    end

    describe '#text_label' do
      it 'is aliased with #display_label && #short_label' do
        expect(subject.text_label).to eq(subject.display_label)
        expect(subject.text_label).to eq(subject.short_label)
      end

      it 'equals the chrono_delta_label' do
        expect(subject.text_label).to eq(subject.chrono_delta_label)
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  context 'with a row that contains valid meeting reservation data,' do
    subject { described_class.decorate(fixture_row) }

    let(:fixture_row) { FactoryBot.create(:import_queue, uid: 'res', request_data: timing_request_data) }

    describe '#chrono_result_label' do
      it 'is empty' do
        expect(subject.chrono_result_label).to be_empty
      end
    end

    describe '#chrono_delta_label' do
      it 'is empty' do
        expect(subject.chrono_delta_label).to be_empty
      end
    end

    describe '#text_label' do
      it 'is aliased with #display_label && #short_label' do
        expect(subject.text_label).to eq(subject.display_label)
        expect(subject.text_label).to eq(subject.short_label)
      end

      it 'includes a pin icon' do
        expect(subject.text_label).to include('📌')
      end

      it 'includes the timing' do
        expect(subject.text_label).to include(ERB::Util.html_escape(fixture_row.req_timing.to_s))
      end

      it 'includes the event type' do
        expect(subject.text_label).to include(fixture_row.req_event_type&.label)
      end

      it 'includes the swimmer name' do
        expect(subject.text_label).to include(ERB::Util.html_escape(fixture_row.req_swimmer_name))
      end

      it 'includes the user name that created the request' do
        expect(subject.text_label).to include(ERB::Util.html_escape(fixture_row.user.name))
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++

  context 'with a generic row that contains any other entity data,' do
    subject { described_class.decorate(fixture_row) }

    let(:fixture_row) { FactoryBot.create(:import_queue, request_data: timing_request_data) }

    describe '#chrono_result_label' do
      it 'is empty' do
        expect(subject.chrono_result_label).to be_empty
      end
    end

    describe '#chrono_delta_label' do
      it 'is empty' do
        expect(subject.chrono_delta_label).to be_empty
      end
    end

    describe '#text_label' do
      it 'is aliased with #display_label && #short_label' do
        expect(subject.text_label).to eq(subject.display_label)
        expect(subject.text_label).to eq(subject.short_label)
      end

      it 'includes the target entity name of the request' do
        expect(subject.text_label).to include(fixture_row.target_entity)
      end

      it 'includes the user name that created the request' do
        expect(subject.text_label).to include(ERB::Util.html_escape(fixture_row.user.name))
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
