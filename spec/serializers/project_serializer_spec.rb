require 'spec_helper'

describe ProjectSerializer do
  let(:serializer) do
    s = ProjectSerializer.new

    s.instance_variable_set(:@model, create(:project_with_contents))
    s.instance_variable_set(:@context, {languages: ['en'],
                                        fields: [:title, :url_labels]})
    s
  end

  describe "#content" do
    it "should return project content for the preferred language" do
      expect(serializer.content).to be_a( Hash )
      expect(serializer.content).to include(:title)
    end
  end

  describe "#urls" do
    it "should return the translated version of the url labels" do
      urls = [{"label" => "Blog",
               "url" => "http://blog.example.com/"},
              {"label" => "Twitter",
               "url" => "http://twitter.com/example"}]
      expect(serializer.urls).to eq(urls)
    end
  end
end
