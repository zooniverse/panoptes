require 'spec_helper'

describe CsvDumps::ClassificationScope do
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow, subjects: [subject])
  end
  let(:cache) { ClassificationDumpCache.new }

  let(:scope) { described_class.new(project, cache) }

  it "should find all the classifications" do
    expect { |b| scope.each(&b) }.to yield_successive_args(*classifications)
  end
end
