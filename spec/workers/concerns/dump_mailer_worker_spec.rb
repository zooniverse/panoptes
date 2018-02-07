require 'spec_helper'

describe DumpMailerWorker do
  let(:users) { create_list(:user, 2) }
  let(:owner) { users.sample }
  let(:resource) do
    double(id: 1, class: Workflow, communication_emails: [owner.email])
  end
  let(:metadata) { {"recipients" => users.map(&:id) } }
  let(:medium) {double(id: 2, get_url: nil, metadata: metadata) }
  let(:worker_class) do
    Class.new do
      include DumpWorker
      include DumpMailerWorker

      attr_reader :project, :medium

      def initialize(resource, medium)
        @resource = resource
        @medium = medium
      end

      def dump_target
        "classifications"
      end
    end
  end

  describe 'queueing notification emails' do
    let(:worker) { worker_class.new(resource, medium) }
    let(:expected_emails) { users.map(&:email) }

    before do
      expect(worker.mailer)
      .to receive(:perform_async)
      .with(resource.id, "workflow", nil, expected_emails)
      .once
      .and_call_original
    end

    it 'queues up an email job' do
      worker.send_email
    end

    context "with no specified recipients" do
      let(:metadata) { { } }
      let(:expected_emails) { [ owner.email ] }

      it 'queues an email to the owner' do
        worker.send_email
      end
    end
  end
end
