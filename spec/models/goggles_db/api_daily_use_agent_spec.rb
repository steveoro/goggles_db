# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_application_record_examples'
require 'support/shared_method_existence_examples'
require 'support/shared_sorting_scopes_examples'
require 'support/shared_filtering_scopes_examples'

module GogglesDb
  RSpec.describe APIDailyUseAgent do
    shared_examples_for 'a valid APIDailyUseAgent instance' do
      it 'is valid' do
        expect(subject).to be_a(described_class).and be_valid
      end

      # Presence of fields:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[user_agent day count]
      )

      it_behaves_like(
        'responding to a list of class methods',
        %i[increase_for!]
      )

      it_behaves_like('ApplicationRecord shared interface')
    end

    before { expect(minimum_domain.count).to be_positive }

    #-- ------------------------------------------------------------------------
    #++

    let(:minimum_domain) do
      ((Time.zone.today - 7.days)..Time.zone.today).each { |day| FactoryBot.create(:api_daily_use_agent, day:) }
      expect(described_class.count).to be >= 7
      # Add 1 more row just to have a static agent to test:
      FactoryBot.create(:api_daily_use_agent, user_agent: 'Test/FakeAgent/1.0')
      described_class.all
    end

    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:api_daily_use_agent) }

      it_behaves_like('a valid APIDailyUseAgent instance')
    end

    # Sorting scopes:
    describe 'self.by_date' do
      let(:result) { minimum_domain.by_date }

      it_behaves_like('sorting scope by_<ANY_VALUE_NAME> (with prepared result)', described_class, 'day')
    end

    # Filtering scopes:
    describe 'self.for_date' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_date', 'day', Time.zone.today)
    end

    describe 'self.for_agent' do
      it_behaves_like('filtering scope for_<ANY_CHOSEN_FILTER>', described_class, 'for_agent', 'user_agent', 'Test/FakeAgent/1.0')
    end
    #-- ------------------------------------------------------------------------
    #++

    describe 'self.increase_for!' do
      context 'given the chosen (user_agent, day) tuple exists,' do
        let(:existing_row) { minimum_domain.sample }

        it 'increases its value by 1' do
          expect { described_class.increase_for!(existing_row.user_agent, existing_row.day) }.to change { existing_row.reload.count }.by(1)
        end
      end

      context 'if the chosen (user_agent, day) tuple is new,' do
        let(:new_built_row) { FactoryBot.build(:api_daily_use_agent) }

        it 'creates a corresponding row, setting its initial value to 1' do
          expect { described_class.increase_for!(new_built_row.user_agent, new_built_row.day) }.to change(described_class, :count).by(1)
          expect(described_class.where(user_agent: new_built_row.user_agent, day: new_built_row.day).first.count).to eq(1)
        end
      end

      context 'when user_agent is blank,' do
        it "stores 'unknown' as user agent" do
          expect { described_class.increase_for!('') }.to change(described_class, :count).by(1)
          expect(described_class.where(user_agent: 'unknown', day: Time.zone.today).count).to eq(1)
        end
      end

      context 'when user_agent is nil,' do
        it "stores 'unknown' as user agent" do
          expect { described_class.increase_for!(nil) }.to change(described_class, :count).by(1)
          expect(described_class.where(user_agent: 'unknown', day: Time.zone.today).count).to eq(1)
        end
      end
    end

    describe 'self.top_agents' do
      before do
        3.times { |n| FactoryBot.create(:api_daily_use_agent, user_agent: "Bot/1.0 #{n + 1}", count: (n + 1) * 10) }
      end

      let(:result) { described_class.top_agents(day_from: Time.zone.today - 1.day, day_to: Time.zone.today) }

      it 'returns a non-empty array of results' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result.to_a).not_to be_empty
      end

      it 'returns results sorted by descending total_count' do
        expect(result.map(&:total_count)).to eq(result.map(&:total_count).sort.reverse)
      end
    end
  end
end
