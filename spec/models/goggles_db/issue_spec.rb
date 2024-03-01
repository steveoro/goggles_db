# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe Issue do
    shared_examples_for 'a valid Issue instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[user]
      )

      it_behaves_like(
        'responding to a list of methods',
        %i[deletable? processable? critical? data]
      )

      # Presence of fields:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[req code priority status]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end
    #-- ------------------------------------------------------------------------
    #++

    %i[
      issue
      issue_type0 issue_type1a issue_type1b issue_type1b1
      issue_type2b1 issue_type3b issue_type3c issue_type4
    ].each do |factory_sym|
      context "when using the #{factory_sym} factory, the resulting instance" do
        subject { FactoryBot.create(factory_sym) }

        it_behaves_like('a valid Issue instance')
      end
    end

    let(:fixture_user) { GogglesDb::User.first(50).sample }

    let(:minimum_domain) do
      Prosopite.pause
      FactoryBot.create_list(:issue, 5)

      # Scrambled list of statuses:
      (0..6).to_a.sample(7).each { |i| FactoryBot.create(:issue, status: i) }
      # Scrambled list of priorities:
      (0..described_class::MAX_PRIORITY).to_a.sample(described_class::MAX_PRIORITY + 1).each do |i|
        FactoryBot.create(:issue, priority: i)
      end

      # List of issues for a specific user:
      FactoryBot.create_list(:issue, 3, user: fixture_user)

      # List of issues with a specific code:
      FactoryBot.create_list(:issue_type4, 3)
      Prosopite.resume
      described_class.all
    end

    # Make sure the minimum test domain is existing before each test:
    before { expect(minimum_domain.count).to be_positive }

    # Sorting scopes:
    describe 'self.by_priority' do
      let(:result) { minimum_domain.by_priority }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'priority')
    end

    describe 'self.by_status' do
      let(:result) { minimum_domain.by_status }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'status')
    end

    # Filtering scopes:
    describe 'self.deletable' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'deletable', 'deletable?', true
      )
    end

    describe 'self.processable' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'processable', 'processable?', true
      )
    end

    describe 'self.prioritized' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'prioritized', 'priority', 1
      )
    end

    describe 'self.urgent' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'urgent', 'priority', 2
      )
    end

    describe 'self.critical' do
      it_behaves_like(
        'filtering scope <ANY_FILTER_NAME> on a field with implicit value',
        described_class, 'critical', 'priority', 3
      )
    end

    describe 'self.for_user' do
      it_behaves_like('filtering scope for_<ANY_ENTITY_NAME>', described_class, 'user')
    end

    describe 'self.for_code' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_code', 'code', '4')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe '#deletable? & #processable' do
      context 'when #status is beyond the processable range' do
        subject { FactoryBot.build(:issue, status: ((described_class::MAX_PROCESSABLE_STATE + 1)..9).to_a.sample) }

        it 'is deletable' do
          expect(subject).to be_deletable
        end

        it 'is NOT processable' do
          expect(subject).not_to be_processable
        end
      end

      context 'when #status is within the processable range' do
        subject { FactoryBot.build(:issue, status: (0..described_class::MAX_PROCESSABLE_STATE).to_a.sample) }

        it 'is NOT deletable' do
          expect(subject).not_to be_deletable
        end

        it 'is processable' do
          expect(subject).to be_processable
        end
      end
    end

    describe '#critical?' do
      context 'when #priority is MAX' do
        subject { FactoryBot.build(:issue, priority: described_class::MAX_PRIORITY) }

        it 'is critical' do
          expect(subject).to be_critical
        end
      end

      context 'when #priority is not MAX' do
        subject { FactoryBot.build(:issue, priority: (0...described_class::MAX_PRIORITY).to_a.sample) }

        it 'is NOT critical' do
          expect(subject).not_to be_critical
        end
      end
    end
  end
end
