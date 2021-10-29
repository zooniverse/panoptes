# frozen_string_literal: true

require 'spec_helper'

describe CsvDumps::ClassificationScope do
  let(:workflow) { create(:workflow) }
  let(:inactive_workflow) { create(:workflow, activated_state: 'inactive') }
  let(:project) { workflow.project }
  let(:subject) { create(:subject, project: project, subject_sets: [create(:subject_set, workflows: [workflow])]) }
  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow, subjects: [subject])
  end
  let(:cache) { ClassificationDumpCache.new }
  let(:classification_lookup_scope) { project.classifications }
  let(:scope) { described_class.new(project, cache, classification_lookup_scope) }

  before do
    classifications
  end

  it 'correctly finds and yields the scoped classifications' do
    expect { |b| scope.each(&b) }.to yield_successive_args(*classifications)
  end

  it 'does not include inactive workflow classification data' do
    inactive_classification = create(:classification, project: project, workflow: inactive_workflow, subjects: [subject])
    classifications = []
    scope.each { |c| classifications << c }
    expect(classifications).not_to include(inactive_classification)
  end

  context 'with a custom resource classifications scope' do
    let(:classification_lookup_scope) { Classification.where(id: classifications.first) }

    it 'uses the injected classification scope'do
      allow(classification_lookup_scope).to receive(:complete).and_call_original
      scope.each { |c| }
      expect(classification_lookup_scope).to have_received(:complete).once
    end
  end
end
