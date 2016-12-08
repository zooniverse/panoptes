require 'spec_helper'

describe DumpMailerWorker do
  let(:resource) { double(id: 1, class: Workflow) }
  let(:users) { create_list(:user, 2) }
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

    it 'queues up an email job' do
      expect(worker.mailer)
        .to receive(:perform_async)
        .with(resource.id, "workflow", nil, users.map(&:email))
        .once
        .and_call_original
      worker.send_email
    end

    context "with no recipients" do
      let(:users) { [] }

      it 'does not queue an email job' do
        expect(worker.mailer).to receive(:perform_async).never
        worker.send_email
      end
    end
  end
end
