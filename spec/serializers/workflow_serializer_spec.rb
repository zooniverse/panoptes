require 'spec_helper'

describe WorkflowSerializer do
  let(:workflow) { create(:workflow_with_contents) }
  let(:content) { workflow.workflow_contents.first }
  
  let(:serializer) do
    serializer = WorkflowSerializer.new
    serializer.instance_variable_set(:@model, workflow)
    serializer.instance_variable_set(:@context,
                                     {languages: ['en']})
    serializer
  end
  
  describe "#tasks" do
    it 'should return the translated tasks' do
      expect(serializer.tasks['interest']['question']).to eq('Draw a circle')
    end
  end

  describe "#version" do
    it 'should be a string of the current workflow version id and the workflow content version id', :versioning do
      expect(serializer.version).to eq("#{workflow.versions.last.id}.#{content.versions.last.id}")
    end
  end

  describe "#content_language" do
    it 'should return the language of the content being used' do
      expect(serializer.content_language).to eq("en")
    end
  end
end
