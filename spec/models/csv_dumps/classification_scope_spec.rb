require 'spec_helper'

describe CsvDumps::ClassificationScope do
  let(:workflow) { create(:workflow) }
  let(:inactive_workflow) { create(:workflow, activated_state: "inactive") }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow, subjects: [subject])
  end
  let!(:unincluded_classification) { create(:classification, project: project, workflow: inactive_workflow, subjects: [subject]) }
  let(:cache) { ClassificationDumpCache.new }

  let(:scope) { described_class.new(project, cache) }

  it "should find all correctly scoped classifications" do
    expect { |b| scope.each(&b) }.to yield_successive_args(*classifications)
  end
end
