require 'spec_helper'

RSpec.describe ClassificationWorker do
  let(:classification_worker) { ClassificationWorker.new }

  describe "perform" do
    let(:classification) { create(:classification) }

    context "create action" do
      it "should call lifecycle" do
        expect(ClassificationLifecycle).to receive(:perform).with(classification, "create")
        classification_worker.perform(classification.id, "create")
      end
    end

    context "update action" do
      it "should call lifecycle" do
        expect(ClassificationLifecycle).to receive(:perform).with(classification, "update")
        classification_worker.perform(classification.id, "update")
      end
    end

    context "other action" do
      it 'should raise an error' do
       expect do
         classification_worker.perform(classification.id, nil)
       end.to raise_error("Invalid Post-Classification Action")
      end
    end
  end
end
