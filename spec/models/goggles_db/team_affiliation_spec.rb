# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe TeamAffiliation, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team_affiliation) }

      it 'is valid' do
        expect(subject).to be_a(TeamAffiliation).and be_valid
      end

      it_behaves_like(
        'having one or more required associations',
        %i[season team]
      )
      it 'has a valid Season' do
        expect(subject.season).to be_a(Season).and be_valid
      end
      it 'has a valid Team' do
        expect(subject.team).to be_a(Team).and be_valid
      end

      it_behaves_like(
        'responding to a list of methods',
        %i[season_type badges
           number]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    # TODO
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    # TODO
  end
end
