# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetImportCompletedMailer, type: :mailer do
  let(:subject_set) { create(:subject_set, num_workflows: 0) }
  let(:subject_set_import) { create(:subject_set_import, subject_set: subject_set) }
  let(:project) { subject_set.project }

  describe '#notify_project_team' do
    let(:mail) { described_class.notify_project_team(project, subject_set_import) }

    it 'mails the users' do
      expect(mail.to).to match_array(project.communication_emails)
    end

    it 'includes the subject' do
      expect(mail.subject).to include('Your Zooniverse project - subject set import success')
    end

    it 'includes the subject set name' do
      expect(mail.body.encoded).to include("subject set named: '#{subject_set.display_name}'")
    end

    it 'includes the subject sets lab link' do
      expect(mail.body.encoded).to include("#{Panoptes.frontend_url}/lab/#{project.id}/subject-sets/#{subject_set.id}")
    end

    it 'comes from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'has the success statement' do
      expect(mail.body.encoded).to include('has completed successfully.')
    end

    context 'with a failed subject set import' do
      let(:subject_set_import) { create(:subject_set_import, subject_set: subject_set, failed_count: 1) }

      it 'includes the failed subject suffix' do
        expect(mail.subject).to include('Your Zooniverse project - subject set import completed with errors')
      end

      it 'reports the failures statement' do
        expect(mail.body.encoded).to include('There were some errors when importing your manifest')
      end
    end
  end
end
