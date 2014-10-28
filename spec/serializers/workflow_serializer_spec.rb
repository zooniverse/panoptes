require 'spec_helper'

describe WorkflowSerializer do
  describe "#tasks" do
    it 'should return the translated tasks' do
      serializer = WorkflowSerializer.new
      serializer.instance_variable_set(:@model,
                                       create(:workflow_with_contents))
      
      serializer.instance_variable_set(:@context,
                                       {languages: ['en']})
      expect(serializer.tasks['interest']['question']).to eq('Draw a circle')
    end
  end
end
