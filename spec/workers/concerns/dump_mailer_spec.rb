require 'spec_helper'

describe DumpMailer do
  let(:users) { create_list(:user, 2) }
  let(:owner) { users.sample }
  let(:resource) { Project.new(id: 1, owner: owner) }
  let(:metadata) { {"recipients" => users.map(&:id) } }
  let(:medium) { instance_double("Medium", id: 2, metadata: metadata) }
  let(:dump_mailer) { described_class.new(resource, medium, "classifications") }

  describe 'queueing notification emails' do
    let(:expected_emails) { users.map(&:email) }

    before do
      expect(ClassificationDataMailerWorker)
      .to receive(:perform_async)
      .with(resource.id, "project", instance_of(String), expected_emails)
      .once
      .and_call_original
    end

    it 'queues up an email job' do
      expected_emails = users.map(&:email)
      allow(dump_mailer).to receive(:emails).and_return(expected_emails)
      dump_mailer.send_email
    end

    context "with no specified recipients" do
      let(:metadata) { { } }
      let(:expected_emails) { [ owner.email ] }

      it 'queues an email to the owner' do
        dump_mailer.send_email
      end
    end

    context 'with emptry recipients list' do
      let(:metadata) { { 'recipients' => [] } }
      let(:expected_emails) { [owner.email] }

      it 'queues an email to the owner' do
        dump_mailer.send_email
      end
    end
  end

  describe 'lab_export_url' do
    let(:resource) { Project.new(id: 1) }
    let(:project_id) { resource.id }
    let(:lab_url) { "#{Panoptes.frontend_url}/lab/#{project_id}/data-exports" }

    it 'correctly determines the lab url' do
      expect(dump_mailer.lab_export_url).to eq(lab_url)
    end

    context "when the resource is a workflow" do
      let(:resource) { Workflow.new(project_id: 2) }
      let(:project_id) { resource.project_id }

      it 'corretly determines the lab url' do
        expect(dump_mailer.lab_export_url).to eq(lab_url)
      end
    end

    context 'when the resource is a subject set' do
      let(:resource) { SubjectSet.new(project_id: 2) }
      let(:project_id) { resource.project_id }
      let(:lab_url) { "#{Panoptes.frontend_url}/lab/#{project_id}/data-exports?subject-sets=#{resource.id}" }

      it 'corretly determines the lab url' do
        expect(dump_mailer.lab_export_url).to eq(lab_url)
      end
    end
  end
end
