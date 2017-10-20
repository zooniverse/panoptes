require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow, subjects: [subject])
  end
  let(:classification_row_exports) do
    classifications.map do |c|
      ClassificationExportRow.create_from_classification(c)
    end
  end

  describe "#perform" do
    let(:num_entries) { classification_row_exports.size + 1 }
    it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"

    context "with read slave enable" do
      before do
        Panoptes.flipper["dump_data_from_read_slave"].enable
      end

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"
    end

    context "with multi subject classification" do
      let(:second_subject) { create(:subject, project: project, subject_sets: subject.subject_sets) }
      let(:classifications) do
        [ create(:classification, project: project, workflow: workflow, subjects: [subject, second_subject]) ]
      end
      let(:num_entries) { classification_row_exports.size + 1 }

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export"
    end
  end

  describe "#completed_project_classifications" do
    before(:each) do
      allow(worker).to receive(:resource).and_return(project)
    end

    it "should find all the classifications" do
      expect(worker.send(:completed_resource_classifications)).to match_array(classifications)
    end
  end
end
