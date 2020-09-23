# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_method_existance_examples'

module GogglesDb
  RSpec.describe Team, type: :model do
    context 'when using the factory, the resulting instance' do
      subject { FactoryBot.create(:team) }

      it 'is valid' do
        expect(subject).to be_a(Team).and be_valid
      end

      # it_behaves_like(
      #   'having one or more required associations',
      #   %i[season season_type federation_type]
      # )
      # it 'has a valid Season' do
      #   expect(subject.season).to be_a(Season).and be_valid
      # end

      it_behaves_like(
        'responding to a list of methods',
        %i[city badges swimmers team_affiliations seasons season_types
           address phone_mobile phone_number fax_number e_mail contact_name
           home_page_url]
      )

      # Presence of fields & requiredness:
      it_behaves_like(
        'having one or more required & present attributes (invalid if missing)',
        %i[name editable_name]
      )
    end
    #-- ------------------------------------------------------------------------
    #++

    # Sorting scopes:
    describe 'self.by_name' do
      let(:result) { subject.class.by_name }
      it 'is a Team relation' do
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to all be_a(Team)
      end
    end
    #-- ------------------------------------------------------------------------
    #++

    # Filtering scopes:
    # TODO
  end
end
