require 'spec_helper'

describe ProjectSerializer do
  let(:project) { create(:full_project, state: "finished", live: false) }
  let(:context) { {languages: ['en'], fields: [:title, :url_labels]} }

  let(:serializer) do
    s = ProjectSerializer.new
    s.instance_variable_set(:@model, project)
    s.instance_variable_set(:@context, context)
    s
  end

  describe 'preloading associations for page' do
    it 'preloads avatars only with cards context' do
      expect_any_instance_of(Project::ActiveRecord_Relation)
        .to receive(:preload)
        .with(:avatar)
        .and_call_original
      ProjectSerializer.page({}, Project.all, {cards: true})
    end

    it 'preloads the specified associations by default' do
      expect_any_instance_of(Project::ActiveRecord_Relation)
        .to receive(:preload)
        .with(*ProjectSerializer.preloads)
        .and_call_original
      ProjectSerializer.page({}, Project.all, {})
    end

    it 'manually preloads the workflow associations' do
      project
      expect(described_class)
        .to receive(:preload_workflows)
        .with(Project.all.pluck(:id))
        .and_call_original
      ProjectSerializer.page({}, Project.all, {})
    end

    it 'handles includes correctly' do
      project
      expected_workflow_ids = project.workflows.pluck(:id).map(&:to_s)
      params = { include: 'workflows,active_workflows' }
      result = described_class.page(params, Project.all, {})
      linked_worklfow_ids = result.dig(:linked, :workflows).map { |w| w[:id] }
      expect(linked_worklfow_ids).to match_array(expected_workflow_ids)
    end
  end

  it_should_behave_like "a panoptes restpack serializer", "test_owner_include", "test_blank_links" do
    let(:resource) { project }
    let(:includes) { %i(workflows active_workflows subject_sets project_roles pages organization) }
    let(:preloads) { ProjectSerializer.preloads }
    let(:expected_links) do
      non_owners_includes = described_class.can_includes - [:owners]
      non_owners_includes | [:owner] | described_class.media_links
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

  describe "#state" do
    it "includes the state" do
      expect(serializer.state).to eq project.state
    end

    describe 'can filter by state' do
      let(:paused_live_project) { create(:full_project, state: "paused", live: true) }
      let(:paused_project) { create(:full_project, state: "paused", live: false) }
      let(:live_project) { create(:full_project, state: nil, live: true) }

      before do
        paused_live_project.save
        live_project.save
        paused_project.save
        project.save
      end

      it 'includes filtered projects' do
        results = described_class.page({"state" => "paused"}, Project.all)
        found_project_ids = results[:projects].map { |p| p[:id] }
        expected_project_ids = [ paused_project.id, paused_live_project.id].map(&:to_s)
        expect(found_project_ids).to match_array(expected_project_ids)
      end

      it 'includes non-enum states' do
        results = described_class.page({"state" => "live"}, Project.all)
        expect(results[:projects].map { |p| p[:id] }).to include(live_project.id.to_s)
        expect(results[:projects].count).to eq(1)
      end

      it 'does not include projects with a state, even if live' do
        results = described_class.page({"state" => "live"}, Project.all)
        expect(results[:projects].map { |p| p[:id] }).not_to include(paused_live_project.id.to_s)
        expect(results[:projects].map { |p| p[:id] }).not_to include(paused_project.id.to_s)
      end
    end
  end

  describe "#avatar_src" do
    let(:avatar) { double("avatar", external_link: external_url, src: src) }
    let(:src) { nil }
    let(:external_url) { nil }

    context "without external" do
      let(:src) { "http://subject1.zooniverse.org" }

      it "should return the src by default" do
        allow(project).to receive(:avatar).and_return(avatar)
        expect(serializer.avatar_src).to eq(src)
      end
    end

    context "with an external url" do
      let(:external_url) { "http://test.example.com" }

      it "should return the external src if set" do
        allow(project).to receive(:avatar).and_return(avatar)
        expect(serializer.avatar_src).to eq(external_url)
      end
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

  describe "active workflows" do
    let(:active_workflow) { project.workflows.first }
    let!(:inactive_workflow) { create(:workflow, project: project, active: false) }
    let(:serialized) { ProjectSerializer.resource({}, Project.where(id: project.id), context) }

    it "includes a list of only active workflows in the links" do
      expect(serialized[:projects][0][:links][:active_workflows]).to contain_exactly(active_workflow.id.to_s)
    end
  end

  describe "tags" do
    let(:tag) { create(:tag) }
    let(:project) { tag.tagged_resources.first.resource }
    let(:tag_names){ [ tag.name ]}

    it "should only return the tag strings array" do
      expect(serializer.tags).to eq(tag_names)
    end

    it "should only return the tag strings array when preloaded" do
      project.tags
      expect(serializer.tags).to eq(tag_names)
    end
  end
end
