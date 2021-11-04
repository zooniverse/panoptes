require 'spec_helper'

RSpec.describe ClassificationsDumpWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject_set) { create(:subject_set, project: project, workflows: [workflow]) }
  let(:subject) { create(:subject, project: project, subject_sets: [subject_set]) }
  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow, subjects: [subject])
  end

  describe "#perform" do
    it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export" do
      let(:num_entries) { classifications.size + 1 }
    end

    it_behaves_like 'rate limit dump worker'

    context "with standby read replica enabled" do
      before do
        Panoptes.flipper["dump_data_from_read_replica"].enable
      end

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export" do
        let(:num_entries) { classifications.size + 1 }
      end
    end

    context "with multi subject classification" do
      let(:second_subject) { create(:subject, project: project, subject_sets: subject.subject_sets) }
      let(:classifications) do
        [ create(:classification, project: project, workflow: workflow, subjects: [subject, second_subject]) ]
      end

      it_behaves_like "dump worker", ClassificationDataMailerWorker, "project_classifications_export" do
        let(:num_entries) { classifications.size + 1 }
      end
    end

    context 'with a workflow as a resource', :focus do
      it_behaves_like 'dump worker', ClassificationDataMailerWorker, 'workflow_classifications_export' do
        let(:resource) { workflow }
        let(:num_entries) { classifications.size + 1 }
      end
    end

    context 'with a subject set as a resource' do
      it_behaves_like 'dump worker', ClassificationDataMailerWorker, 'subject_set_classifications_export' do
        let(:resource) { subject_set }
        let(:num_entries) { classifications.size + 1 }
      end
    end
  end
end
