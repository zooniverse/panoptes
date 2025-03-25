# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Formatter::Csv::V2::Annotation do
  let(:workflow_version) { build_stubbed(:workflow_version, workflow: workflow, tasks: workflow.tasks, strings: workflow.strings) }
  let(:classification) do
    build_stubbed(:classification, subjects: [], workflow: workflow, annotations: [annotation])
  end
  let(:cache) { instance_double('ClassificationDumpCache') }
  let(:formatter) do
    described_class.new(classification, classification.annotations[0], cache)
  end

  before do
    maj, min = classification.workflow_version.split('.').map(&:to_i)
    allow(cache).to receive(:workflow_at_version).with(workflow, maj, min).and_return(workflow_version)
  end

  context 'with a non-dropdown task workflow and annotation' do
    let(:workflow) { build_stubbed(:workflow) }
    let(:annotation) { { 'task' => 'interest', 'value' => {} } }
    let(:default_formatter) { formatter.default_formatter }

    before do
      allow(default_formatter).to receive(:to_h)
    end

    it 'uses the default annotation formatter' do
      formatter.to_h
      expect(default_formatter).to have_received(:to_h)
    end
  end

  context 'with a v2 dropdown (simple) task' do
    # details on what allowCreate wf task values for dropdowns do
    # and how that relates to the annotaion value `option: false`
    # https://github.com/zooniverse/caesar/pull/842#issuecomment-499586993
    let(:workflow) { build_stubbed(:workflow, :dropdown_simple) }
    let(:annotation) do
      {
        'task' => 'T1',
        'value' => { 'selection' => 2, 'option' => true },
        'taskType' => 'dropdown-simple'
      }
    end
    let(:dropdown_formatter) { instance_double(Formatter::Csv::V2::DropdownAnnotation) }

    before do
      allow(Formatter::Csv::V2::DropdownAnnotation).to receive(:new).and_return(dropdown_formatter)
      allow(dropdown_formatter).to receive(:format)
    end

    it 'uses the dropdown annotation formatter' do
      formatter.to_h
      expect(dropdown_formatter).to have_received(:format)
    end
  end
end
