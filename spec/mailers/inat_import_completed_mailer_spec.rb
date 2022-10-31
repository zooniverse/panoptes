# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InatImportCompletedMailer, type: :mailer do
  let(:subject_set) { create(:subject_set, num_workflows: 0) }
  let(:ss_import) { create(:subject_set_import, subject_set: subject_set) }
  let(:project) { subject_set.project }

  describe '#inat_import_complete' do
    let(:mail) { described_class.inat_import_complete(ss_import) }

    it 'mails the user' do
      expect(mail.to).to match_array([ss_import.user.email])
    end

    it 'includes the subject' do
      expect(mail.subject).to include('iNaturalist subject import was successful!')
    end

    it 'includes the subject set name' do
      expect(mail.body.encoded).to include("subjects were imported into subject set '#{subject_set.display_name}'")
    end

    it 'includes the subject sets lab link' do
      expect(mail.body.encoded).to include("#{Panoptes.frontend_url}/lab/#{project.id}/subject-sets/#{subject_set.id}")
    end

    it 'comes from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'has the success statement' do
      expect(mail.body.encoded).to include('The iNaturalist observations have been imported successfully.')
    end

    context 'with a failed subject set import' do
      let(:ss_import) { create(:subject_set_import, subject_set: subject_set, failed_count: 1) }

      it 'includes the failed subject suffix' do
        expect(mail.subject).to include('Your iNaturalist subject import completed with errors')
      end

      it 'reports the failures statement' do
        expect(mail.body.encoded).to include('There were some errors when importing your iNaturalist observations.')
      end
    end
  end
end
