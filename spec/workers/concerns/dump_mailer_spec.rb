require 'spec_helper'

describe DumpMailer do
  let(:users) { create_list(:user, 2) }
  let(:owner) { users.sample }
  let(:resource) do
    double(id: 1, class: Workflow, communication_emails: [owner.email])
  end
  let(:metadata) { {"recipients" => users.map(&:id) } }
  let(:medium) { double(id: 2, get_url: nil, metadata: metadata) }
  let(:dump_mailer) { described_class.new(resource, medium, "classifications") }

  describe 'queueing notification emails' do
    let(:expected_emails) { users.map(&:email) }

    before do
      expect(ClassificationDataMailerWorker)
      .to receive(:perform_async)
      .with(resource.id, "workflow", nil, expected_emails)
      .once
      .and_call_original
    end

    it 'queues up an email job' do
      dump_mailer.send_email
    end

    context "with no specified recipients" do
      let(:metadata) { { } }
      let(:expected_emails) { [ owner.email ] }

      it 'queues an email to the owner' do
        dump_mailer.send_email
      end
    end
  end
end
