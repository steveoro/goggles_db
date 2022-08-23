# frozen_string_literal: true

require 'rails_helper'

# REQUIRES/ASSUMES:
# - subject......: the actual subject to be tested
# - attach_msg...: member/helper name for the attach object
# => creates & purges the temp file '<Rails.root/>tmp/storage/test.sql'
shared_examples_for 'active storage field with local file' do |attach_msg|
  # Remove all temp data folders and data.
  # During tests, objects are wrapped in a transaction so destroy is never called upon them and their
  # corresponding data folder for the blobs stays there even after purging the attachable itself.
  # See: https://guides.rubyonrails.org/v6.0/active_storage_overview.html#discarding-files-stored-during-integration-tests
  after { FileUtils.rm_rf(Rails.root.join('tmp/storage')) }

  it 'allows a storage file to be attached and managed' do
    attachable = subject.send(attach_msg)
    # Verify basic interface coherence:
    %i[attach attached? detach purge blank?].each { |method| expect(attachable).to respond_to(method) }
  end

  context 'when attaching a local file,' do
    let(:text_contents) { "SELECT COUNT(*) FROM users;\r\n" }

    it "can be accessed via the ##{attach_msg} member and disposed with #purge" do
      # Create the local temp storage file:
      file_path = Rails.root.join('tmp/test.sql')
      File.open(file_path, 'w') { |f| f.write(text_contents) }

      # Attach the file to the attachable:
      attachable = subject.send(attach_msg)
      attachable.attach(io: File.open(file_path), filename: File.basename(file_path), content_type: 'application/sql')
      expect(attachable).to be_present && be_persisted

      # Open & retrieve the persisted file contents using our helper convention:
      # (which assumes the helper getter will be named <'attach_msg'_contents>):
      expect(subject.send("#{attach_msg}_contents")).to eq(text_contents)

      attachable.purge
      expect(attachable).to be_blank
    end
  end
end
#-- ---------------------------------------------------------------------------
#++
