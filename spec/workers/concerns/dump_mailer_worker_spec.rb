require 'spec_helper'

describe DumpMailerWorker do
  let(:project) { double(id: 1) }

  let(:worker_class) do
    Class.new do
      include DumpWorker
      include DumpMailerWorker

      attr_reader :project, :medium

      def initialize(project, medium)
        @project = project
        @medium = medium
      end

      def dump_target
        "classifications"
      end
    end
  end

  describe 'queueing notification emails' do
    it 'queues up an email job' do
      user1 = create :user
      user2 = create :user
      medium = double(get_url: nil, metadata: {"recipients" => [user1.id, user2.id]})
      worker = worker_class.new(project, medium)
      expect(ClassificationDataMailerWorker).to receive(:perform_async).once
      worker.send_email
    end

    it 'does not queue an email job if there are no recipients' do
      medium = double(get_url: nil, metadata: {"recipients" => []})
      worker = worker_class.new(project, medium)
      expect(ClassificationDataMailerWorker).to receive(:perform_async).never
      worker.send_email
    end
  end
end
