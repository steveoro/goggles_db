# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe CmdFindDbEntity, type: :command do
    describe 'any instance' do
      subject { described_class.new(GogglesDb::Swimmer, complete_name: 'Alloro Stefano') }

      it_behaves_like(
        'responding to a list of methods',
        %i[matches result call errors successful?]
      )
    end
    #-- --------------------------------------------------------------------------
    #++

    shared_examples_for 'CmdFindDbEntity successful #call' do |model_klass, target_key, target_value|
      it 'returns itself' do
        expect(subject).to be_a(described_class)
      end

      it 'is successful' do
        expect(subject).to be_successful
      end

      it 'has a blank #errors list' do
        expect(subject.errors).to be_blank
      end

      it 'has a valid #result' do
        expect(subject.result).to be_a(model_klass).and be_present
        # DEBUG output for tested substitutions: just specify actual fixture_value in shared group call to enable it
        puts "\r\n- #{target_value} => #{subject.result.send(target_key)}" if target_value && target_value != subject.result.send(target_key)
      end

      describe '#matches' do
        it 'is an array of OpenStruct, each with a candidate and a weight' do
          expect(subject.matches).to all respond_to(:candidate).and respond_to(:weight)
        end

        it 'includes the #result in the #matches candidates list' do
          expect(subject.matches.map(&:candidate)).to include(subject.result)
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using valid parameters' do
      context 'matching the specified value,' do
        subject { described_class.call(GogglesDb::Swimmer, complete_name: 'Smith Bao') }

        it_behaves_like('CmdFindDbEntity successful #call', GogglesDb::Swimmer, :complete_name, nil) # disable debug output with nil
      end

      context 'matching a single result (1:1),' do
        [
          # 1:1 matches:
          { klass: GogglesDb::Swimmer, params: { complete_name: 'Alloro Stefano' } },
          { klass: GogglesDb::Swimmer, params: { complete_name: 'Ligabue' } },
          { klass: GogglesDb::Swimmer, params: { complete_name: 'Smith Bao' } },

          { klass: GogglesDb::Team, params: { editable_name: 'West Concetta Swimming Club 2022' } },
          { klass: GogglesDb::Team, params: { editable_name: 'Framistad Swimming Club 2021' } },
          { klass: GogglesDb::Team, params: { editable_name: 'Ogaberg Swimming Club ASD' } },

          { klass: GogglesDb::SwimmingPool, params: { nick_name: 'reggiocomunale25' } },
          { klass: GogglesDb::SwimmingPool, params: { nick_name: 'reggiocomunale50' } },
          { klass: GogglesDb::SwimmingPool, params: { nick_name: 'carpicomunale' } }
        ].each do |fixture|
          describe "#call (#{fixture[:params].inspect})" do
            subject { described_class.call(fixture[:klass], fixture[:params]) }

            it_behaves_like('CmdFindDbEntity successful #call', fixture[:klass], fixture[:params].keys.first, nil)

            it 'has a single-item #matches list' do
              expect(subject.matches.count).to eq(1)
            end
          end
        end
      end

      context 'matching multiple results (1:N),' do
        [
          # 1:N matches:
          { klass: GogglesDb::Swimmer, params: { complete_name: 'White Sha' } },
          { klass: GogglesDb::Swimmer, params: { complete_name: 'Farrell Sha' } },

          { klass: GogglesDb::Team, params: { editable_name: 'North Gia Swimming Club' } },
          { klass: GogglesDb::Team, params: { editable_name: 'East Swimming Club ASD' } },
          { klass: GogglesDb::Team, params: { editable_name: 'Ramiro Swimming Club' } },
          { klass: GogglesDb::Team, params: { editable_name: 'West' } },
          { klass: GogglesDb::Team, params: { editable_name: 'Lake' } }
        ].each do |fixture|
          describe "#call (#{fixture[:params].inspect})" do
            subject { described_class.call(fixture[:klass], fixture[:params]) }

            it_behaves_like('CmdFindDbEntity successful #call', fixture[:klass], fixture[:params].keys.first, nil)

            it 'has possibly multiple #matches' do
              expect(subject.matches.count).to be >= 1
            end
          end
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++

    context 'when using invalid parameters,' do
      shared_examples_for 'CmdFindDbEntity failing' do
        it 'returns itself' do
          expect(subject).to be_a(described_class)
        end

        it 'fails' do
          expect(subject).to be_a_failure
        end

        it 'has a nil #result' do
          expect(subject.result).to be nil
        end
      end

      describe '#call' do
        context 'without a search query parameter,' do
          subject { described_class.call }

          it 'raises an ArgumentError' do
            expect { subject }.to raise_error(ArgumentError)
          end
        end

        context 'with an unsupported search entity,' do
          subject { described_class.call(GogglesDb::User, name: 'steve') }

          it 'raises an ArgumentError' do
            expect { subject }.to raise_error(ArgumentError)
          end
        end

        context 'with a non-existing search value,' do
          subject { described_class.call(GogglesDb::Swimmer, complete_name: impossible_name) }

          let(:impossible_name) { %w[Kqwxy Ykqxz Z1wq Xhk67 ZZZwy9].sample }

          it_behaves_like 'CmdFindDbEntity failing'

          it 'has a non-empty #errors list' do
            expect(subject.errors).to be_present
            expect(subject.errors[:complete_name]).to eq([impossible_name])
          end
        end
      end
    end
    #-- --------------------------------------------------------------------------
    #++
  end
end
