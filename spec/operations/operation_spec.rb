require 'spec_helper'

RSpec.describe Operation do
  describe 'enqueueing jobs' do
    it 'puts jobs onto the queue after the execute method' do
      stub_const("FakeWorker", double(perform_async: true))
      operation = Class.new(Operation) do
        def self.model_name; ActiveModel::Name.new(self, nil, "Foo"); end
        def execute
          enqueue FakeWorker, 1, 2, 3
          true
        end
      end

      operation.run! api_user: ApiUser.new(nil)
      expect(FakeWorker).to have_received(:perform_async).with(1,2,3).once
    end

    it 'does not enqueue if the execute method raises' do
      stub_const("FakeWorker", double(perform_async: true))
      operation = Class.new(Operation) do
        def self.model_name; ActiveModel::Name.new(self, nil, "Foo"); end
        def execute
          enqueue FakeWorker, 1, 2, 3
          raise "something went wrong"
        end
      end

      expect { operation.run api_user: ApiUser.new(nil) }.to raise_exception(RuntimeError)
      expect(FakeWorker).not_to have_received(:perform_async)
    end

    it 'does not enqueue if the execute method raises' do
      stub_const("FakeWorker", double(perform_async: true))
      operation = Class.new(Operation) do
        def self.model_name; ActiveModel::Name.new(self, nil, "Foo"); end
        string :name
        validates :name, presence: true
        def execute
          enqueue FakeWorker, 1, 2, 3
          raise "something went wrong"
        end
      end

      expect(operation.run(api_user: ApiUser.new(nil))).not_to be_valid
      expect(FakeWorker).not_to have_received(:perform_async)
    end
  end
end
