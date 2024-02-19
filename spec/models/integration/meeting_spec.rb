# frozen_string_literal: true

require 'rails_helper'

module GogglesDb
  RSpec.describe Meeting, type: :integration do
    let(:descriptions) { YAML.load_file(GogglesDb::Engine.root.join('spec/fixtures/normalizers/descriptions-212.yml')) }
    let(:list_of_editions_and_names) { descriptions.map { |description| GogglesDb::Normalizers::CodedName.edition_split_from(description) } }

    context 'when testing any label internal helper method using fixtures' do
      it 'does not raise errors due to empty tokens' do
        Prosopite.pause
        list_of_editions_and_names.each_with_index do |edition_and_name, index|
          edition, _name, edition_type_id = edition_and_name
          description = descriptions[index]
          meeting = FactoryBot.build(
            :meeting,
            description:,
            edition:,
            edition_type_id:
          )

          expect { meeting.edition_label }.not_to raise_error
          expect { meeting.name_without_edition }.not_to raise_error
          expect { meeting.name_with_edition }.not_to raise_error
          expect { meeting.condensed_name }.not_to raise_error

          # DEBUG
          # puts "'#{description}' |=> [#{edition}, #{_name}] \t|=> ed.: #{meeting.edition_label}, " \
          #      "cond.: #{meeting.condensed_name}, w/o: #{meeting.name_without_edition}" \
          #      "w/: #{meeting.name_with_edition}"

          # Edition label can be empty sometimes, if the edition type is NONE:
          expect(meeting.edition_label).to be_present unless meeting.edition_type_id == GogglesDb::EditionType::NONE_ID
          # All other helpers are expected never to be empty, always:
          expect(meeting.name_without_edition).to be_present
          expect(meeting.name_with_edition).to be_present
          expect(meeting.condensed_name).to be_present
        end
        Prosopite.resume
      end
    end
  end
end
