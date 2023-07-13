# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GogglesDb::IssueDecorator, type: :decorator do
  describe '#state_flag' do
    (0..6).to_a.each do |index|
      context "when the row has status #{index} ('#{I18n.t("issues.status_#{index}")}')" do
        subject { FactoryBot.build(:issue, status: index).decorate.state_flag }

        it 'is present' do
          expect(subject).to be_present
        end

        it 'is html_safe' do
          expect(subject).to be_html_safe
        end
      end
    end
  end

  describe '#priority_flag' do
    (0..3).to_a.each do |index|
      context "when the row has priority #{index}" do
        subject { FactoryBot.build(:issue, priority: index).decorate.priority_flag }

        it 'is present' do
          expect(subject).to be_present
        end

        it 'is html_safe' do
          expect(subject).to be_html_safe
        end
      end
    end
  end

  describe '#code_flag' do
    GogglesDb::Issue::SUPPORTED_CODES.each do |code|
      context "when the row has code #{code} ('#{I18n.t("issues.label_#{code}")}')" do
        subject { FactoryBot.build(:issue, code:).decorate.code_flag }

        it 'is present' do
          expect(subject).to be_present
        end

        it 'is html_safe' do
          expect(subject).to be_html_safe
        end
      end
    end
  end
end
