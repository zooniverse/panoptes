require 'spec_helper'

RSpec.describe ClassificationExportRowWorker do
  let(:worker) { ClassificationExportRowWorker.new }

  describe "perform" do
    let(:classification) { create(:classification) }

    it "should create an export row" do
      expect(ClassificationExportRow).to receive(:create_from_classification)
      worker.perform(classification.id)
    end

    it "should not raise an error if classification row has already exists" do
      ClassificationExportRow.create_from_classification(classification)
      expect { worker.perform(classification.id) }.not_to raise_error
    end

    context "when classification is incomplete" do
      let(:classification) { create(:classification, completed: false) }

      it "should not create an export row" do
        expect(ClassificationExportRow).not_to receive(:create_from_classification)
        worker.perform(classification.id)
      end
    end
  end
end
