require 'spec_helper'

RSpec.describe ClassificationWorker do
  let(:classification_worker) { ClassificationWorker.new }

  describe "perform" do
    let(:classification) { create(:classification) }

    context ":update" do
      after(:each) do
        classification_worker.perform(classification.id, "update")
      end

      it "should call transact! on the lifecycle" do
        expect_any_instance_of(ClassificationLifecycle).to receive(:update!)
      end
    end

    context ":create" do
      after(:each) do
        classification_worker.perform(classification.id, "create")
      end

      it "should call transact! on the lifecycle" do
        expect_any_instance_of(ClassificationLifecycle).to receive(:create!)
      end
    end

    context "anything else" do
      it 'should raise an error' do
       expect do
         classification_worker.perform(classification.id, nil)
       end.to raise_error("Invalid Post-Classification Action")
      end
    end
  end
end
