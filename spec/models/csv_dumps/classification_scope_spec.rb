# frozen_string_literal: true

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

  it 'correctly finds and yields the scoped classifications' do
    classifications
    expect { |b| scope.each(&b) }.to yield_successive_args(*classifications)
  end

  context 'with inactive workflow classifications' do
    let(:inactive_workflow) { create(:workflow, project: project, activated_state: 'inactive') }
    let(:inactive_classification) do
      create(:classification, project: project, workflow: inactive_workflow, subjects: [subject])
    end

    it 'does not include inactive workflow classification data' do
      inactive_classification
      classifications = []
      scope.each { |c| classifications << c }
      expect(classifications).not_to include(inactive_classification)
    end
  end
end
