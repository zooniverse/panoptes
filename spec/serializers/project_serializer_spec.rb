require 'spec_helper'

describe ProjectSerializer do
  let(:project) { create(:project_with_contents) }
  let(:context) { {languages: ['en'], fields: [:title, :url_labels]} }

  let(:serializer) do
    s = ProjectSerializer.new

    s.instance_variable_set(:@model, project)
    s.instance_variable_set(:@context, context)
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

  describe "media links" do
    let(:links) { [:attached_images, :avatar, :background] }
    let(:serialized) { ProjectSerializer.resource({}, Project.where(id: project.id), context) }

    it 'should include top level links for media' do
      expect(serialized[:links]).to include(*links.map{ |l| "projects.#{l}" })
    end

    it 'should include resource level links for media' do
      expect(serialized[:projects][0][:links]).to include(*links)
    end

    it 'should include hrefs for links' do
      serialized[:projects][0][:links].slice(*links).each do |_, linked|
        expect(linked).to include(:href)
      end
    end

    it 'should include the id for single links' do
      serialized[:projects][0][:links].slice(:avatar, :background).each do |_, linked|
        expect(linked).to include(:id)
      end
    end
  end
end
