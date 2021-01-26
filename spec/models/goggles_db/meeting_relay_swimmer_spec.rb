# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'
require 'support/shared_timing_manageable_examples'
require 'support/shared_to_json_examples'

module GogglesDb
  RSpec.describe MeetingRelaySwimmer, type: :model do
    shared_examples_for 'a valid MeetingRelaySwimmer instance' do
      it 'is valid' do
        expect(subject).to be_a(MeetingRelaySwimmer).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[meeting_relay_result swimmer badge stroke_type
           meeting meeting_session meeting_event meeting_program event_type team]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[relay_order reaction_time]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[minutes seconds hundredths
           minimal_attributes swimmer_attributes
           to_timing to_json]
      )
    end

    context 'any pre-seeded instance' do
      subject { MeetingRelaySwimmer.all.limit(20).sample }
      it_behaves_like('a valid MeetingRelaySwimmer instance')
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:meeting_relay_swimmer) }
      it_behaves_like('a valid MeetingRelaySwimmer instance')
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_order' do
      let(:fixture_row) { FactoryBot.create(:meeting_relay_result_with_swimmers) }
      let(:result) { fixture_row.meeting_relay_swimmers.by_order }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', MeetingRelaySwimmer, 'relay_order')
    end

    # Filtering scopes:
    describe 'self.with_time' do
      it_behaves_like('filtering scope with_time', MeetingRelaySwimmer)
    end
    describe 'self.with_no_time' do
      it_behaves_like('filtering scope with_no_time', MeetingRelaySwimmer)
    end
    #-- ------------------------------------------------------------------------
    #++

    let(:fixture_row) { FactoryBot.create(:meeting_relay_swimmer) }

    describe 'regarding the timing fields,' do
      # subject = fixture_row (can even be just built, not created)
      it_behaves_like 'TimingManageable'
    end

    describe '#minimal_attributes' do
      subject { fixture_row.minimal_attributes }

      it 'is an Hash' do
        expect(subject).to be_an(Hash)
      end
      %w[gender_type stroke_type].each do |association_name|
        it "includes the #{association_name} association key" do
          expect(subject.keys).to include(association_name)
        end
      end
      it "contains the 'synthetized' swimmer details" do
        expect(subject['swimmer']).to be_an(Hash).and be_present
        expect(subject['swimmer']).to eq(fixture_row.swimmer_attributes)
      end
    end

    describe '#to_json' do
      subject { FactoryBot.create(:meeting_relay_swimmer) }

      # Required associations:
      it_behaves_like(
        '#to_json when called on a valid instance',
        %w[meeting_relay_result team badge event_type stroke_type]
      )
    end
  end
end
