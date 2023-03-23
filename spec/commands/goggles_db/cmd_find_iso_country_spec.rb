# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe CmdFindIsoCountry, type: :command do
    context 'when using valid parameters,' do
      [
        %w[Italy IT],
        %w[France FR],
        %w[Germany DE],
        ['United Kingdom', 'GB'],
        ['United States', 'US'],
        %w[Spain ES]
      ].each do |fixture_name, fixture_alpha2|
        describe "#call('#{fixture_name}', '#{fixture_alpha2}')" do
          # fixture_parameters.first, fixture_parameters.last
          subject { described_class.call(fixture_name, fixture_alpha2) }

          let(:result_country) { subject.result }

          it 'returns itself' do
            expect(subject).to be_a(described_class)
          end

          it 'is successful' do
            expect(subject).to be_successful
          end

          it 'has a blank #errors list' do
            expect(subject.errors).to be_blank
          end

          it 'has a valid Country #result' do
            expect(subject.result).to be_a(ISO3166::Country).and be_present
            expect(fixture_name).to eq(subject.result.iso_short_name)
              .or eq(subject.result.unofficial_names.first)
            expect(subject.result.alpha2).to eq(fixture_alpha2)
          end
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using invalid parameters,' do
      let(:fixture_name) { "Q'onoS" }
      let(:fixture_code) { "Q'O" }

      describe '#call' do
        subject { described_class.call(fixture_name, fixture_code) }

        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'fails' do
          expect(subject).to be_a_failure
        end

        it 'has a non-empty #errors list' do
          expect(subject.errors).to be_present
          expect(subject.errors[:name]).to eq([fixture_name])
        end

        it 'has a nil #result' do
          expect(subject.result).to be_nil
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
