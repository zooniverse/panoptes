require 'spec_helper'

describe EventStreamSerializers::ClassificationSerializer do
  let(:classification) { create(:classification) }
  let(:serializer) { described_class.new(Classification.find(classification.id)) }
  let(:adapter) { Serialization::V1Adapter.new(serializer) }

  it 'can process includes' do
    subject = create(:subject)
    classification.subject_ids = [subject.id]
    adapter = described_class.serialize(classification, include: ['subjects'])
    expect(adapter.as_json[:linked]['subjects'].size).to eq(1)
  end

  context 'versioned resources' do
    before(:each) do
      PaperTrail.enabled = true
    end

    after(:each) do
      PaperTrail.enabled = false
    end

    it 'links the correct version of the workflow' do
      classification.update! annotations: [{"task" => "interest", "value" => []}], workflow_version: '1.1'
      old_tasks = classification.workflow.tasks
      classification.workflow.update!(tasks: {"new_task" => {}})

      adapter = described_class.serialize(classification, include: ['workflow'])
      expect(adapter.as_json[:linked]['workflows'][0][:tasks]).to eq(old_tasks)
    end

    it 'links the correct version of the workflow content' do
      classification.update! annotations: [{"task" => "interest", "value" => []}], workflow_version: '1.1'
      old_strings = classification.workflow.primary_content.strings
      classification.workflow.primary_content.update!(strings: {"foo" => "BAR"})

      adapter = described_class.serialize(classification, include: ['workflow_content'])
      expect(adapter.as_json[:linked]['workflow_contents'][0][:strings]).to eq(old_strings)
    end
  end
end
