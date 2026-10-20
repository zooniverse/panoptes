# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserAddedToCollectionMailer, type: :mailer do
  let(:collection) { create(:collection) }
  let(:user) { collection.owner }
  let(:roles) { ['collaborator'] }
  let(:mail) { described_class.added_to_collection(user, collection, roles) }

  describe '#added_to_collection' do
    it 'mails the correct user' do
      expect(mail.to).to include(user.email)
    end

    it 'comes from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq("You've been added to a new Zooniverse collection")
    end

    it 'has the collection name in the body' do
      expect(mail.body.encoded).to match(collection.display_name.to_s)
    end

    it 'includes the collection URL in the body' do
      expect(mail.body.encoded).to match("#{ Panoptes.frontend_url }/collections/#{ collection.slug }")
    end
  end
end
