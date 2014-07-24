require 'spec_helper'

RSpec.describe ProjectSerializer do
  describe "#content" do
    it "should return project content for the preferred language" do
      serializer = ProjectSerializer.new

      serializer.instance_variable_set(:@model, 
                                       create(:project_with_contents))
      serializer.instance_variable_set(:@context,
                                       {languages: ['en'], fields: ['title']})

      expect(serializer.content).to be_a( Hash )
      expect(serializer.content).to include('title')
    end
  end
end
