# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetCompletedMailer, type: :mailer do
  let(:subject_set) { create(:subject_set, num_workflows: 0) }
  let(:project) { subject_set.project }

  describe '#notify_project_team' do
    let(:mail) { described_class.notify_project_team(project, subject_set) }

    it 'mails the users' do
      expect(mail.to).to match_array(project.communication_emails)
    end

    it 'includes the lab link' do
      expect(mail.body.encoded).to include("#{Panoptes.frontend_url}/lab/#{project.id}/data-exports")
    end

    it 'comes from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end
  end
end
