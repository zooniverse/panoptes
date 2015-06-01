require 'spec_helper'
require 'export_json_project'

RSpec.describe Export::JSON::Project do

  def project_attributes
    attrs = Export::JSON::Project.project_attributes
    project.as_json.slice(*attrs).merge!(private: true)
  end

  def project_avatar_attributes
    attrs = Export::JSON::Project.media_attributes
    project.avatar.as_json.slice(*attrs)
  end

  def project_background_attributes
    attrs = Export::JSON::Project.media_attributes
    project.background.as_json.slice(*attrs)
  end

  def project_content_attributes
    attrs = Export::JSON::Project.project_content_attributes
    project_content.as_json.slice(*attrs)
  end

  def workflows_attributes
    attrs = Export::JSON::Project.workflow_attributes
    [].tap do |workflows_attr|
      workflows.each { |workflow| workflows_attr << workflow.as_json.slice(*attrs) }
    end
  end

  def workflow_content_attributes
    attrs = Export::JSON::Project.workflow_content_attributes
    [].tap do |workflow_contents_attr|
      workflow_contents.each do |workflow_content|
        workflow_contents_attr << workflow_content.as_json.slice(*attrs)
      end
    end
  end

  def export_json
    {
      project: project_attributes,
      project_avatar: project_avatar_attributes,
      project_background: project_background_attributes,
      project_content: project_content_attributes,
      workflows: workflows_attributes,
      workflow_contents: workflow_content_attributes
    }.to_json
  end

  def export_values(object_key)
    JSON.parse(exporter.to_json)[object_key]
  end

  let(:project) { create(:full_project) }
  let(:avatar) { project.avatar }
  let(:background) { project.background }
  let(:project_content) { project.primary_content }
  let(:workflows) { project.workflows }
  let(:workflow_contents) { workflows.map(&:primary_content) }
  let(:exporter) { Export::JSON::Project.new(project.id) }
  let(:new_owner) { create(:user) }

  describe "#to_json" do

    it 'return a export in the expected json format' do
      results = JSON.parse(exporter.to_json)
      expected = JSON.parse(export_json)
      expect(results).to eq(expected)
    end

    describe "project" do
      let(:new_project) { Project.new(export_values("project")) }

      it "should be able to rebuild the project from the export" do
        new_project.valid?
        expect(new_project.errors.keys).to match_array([:owner, :project_contents])
      end

      it "should be private by default" do
        expect(new_project.private).to eq(true)
      end
    end

    describe "project_avatar" do
      let(:new_project_avatar) do
        Medium.new(export_values("project_avatar"), linked: project)
      end

      it "should be able to rebuild the project_avatar from the export" do
        expect(new_project_avatar).to be_valid
      end

      context "when the project avatar is missing" do

        it "should not have a project_avatar data" do
          allow_any_instance_of(Project).to receive(:avatar).and_return(nil)
          expect(export_values("project_avatar")).to be_nil
        end
      end
    end

    describe "project_background" do
      let(:new_project_background) do
        Medium.new(export_values("project_background"), linked: project)
      end

      it "should be able to rebuild the new_project_background from the export" do
        expect(new_project_background).to be_valid
      end
    end

    describe "project_content" do
      let(:new_project_content) do
        ProjectContent.new(export_values("project_content"))
      end

      it "should be able to rebuild the project_contents from the export" do
        expect(new_project_content).to be_valid
      end

      it "should be for the default project language" do
        expect(new_project_content.language).to eq(project.primary_language)
      end
    end

    describe "workflows" do
      it "should be able to rebuild each workflow from the export" do
        export_values("workflows").each do |workflow_attrs|
          new_workflow = Workflow.new(workflow_attrs)
          new_workflow.valid?
          expect(new_workflow.errors.keys).to match_array([:workflow_contents, :project])
        end
      end
    end

    describe "workflow_contents" do

      it "should be able to rebuild all the workflow_contents from the export" do
        export_values("workflow_contents").each do |workflow_attrs|
          new_workflow_content = WorkflowContent.new(workflow_attrs)
          expect(new_workflow_content).to be_valid
        end
      end

      it "should be for the default workflow language" do
        export_values("workflow_contents").each_with_index do |attrs, index|
          new_workflow_content = WorkflowContent.new(attrs)
          expected = workflows[index].primary_language
          expect(new_workflow_content.language).to eq(expected)
        end
      end
    end

    describe "valid export" do

      it "should have one workflow_contents for each workflow" do
        num_wkfls = export_values("workflows").size
        num_wcs   = export_values("workflow_contents").size
        expect(num_wkfls).to eq(num_wcs)
      end

      describe "recreated instances" do
        let(:p){ Project.new(export_values("project").merge(owner: new_owner)) }
        let(:instances) do
          [].tap do |instances|
            instances << p
            p.project_contents << ProjectContent.new(export_values("project_content"))
            instances << p.project_contents.first
            instances << p.avatar = Medium.new(export_values("project_avatar"))
            instances << p.background = Medium.new(export_values("project_background"))
            export_values("workflows").each_with_index do |workflow_attrs, index|
              w = Workflow.new(workflow_attrs.merge(project: p))
              w.workflow_contents << WorkflowContent.new(export_values("workflow_contents")[index])
              instances << w << w.workflow_contents.first
            end
          end
        end

        it "should build 8 instances" do
          expect(instances.size).to eq(6)
        end

        it "should be able to recreate the set of valid project instances" do
          expect(instances.map(&:valid?).all?).to eq(true)
        end

        it "should should correctly link the project avatar" do
          instances
          expect(p.avatar).to_not be_nil
        end

        it "should should correctly link the project background" do
          instances
          expect(p.background).to_not be_nil
        end
      end
    end
  end
end
