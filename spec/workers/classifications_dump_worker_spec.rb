require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:classifications) do
    create_list(:classification, 5, project: project, workflow: workflow, subjects: [subject])
  end

  describe "#perform" do
    it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export" do
      let(:num_entries) { classifications.size + 1 }
    end
  end

  describe "#completed_project_classifications" do
    before(:each) do
      allow(worker).to receive(:project).and_return(project)
    end

    it "should find all the classifications" do
      expect(worker.send(:completed_project_classifications)).to match_array(classifications)
    end
  end
end
