require 'spec_helper'
require 'export_json_project'

RSpec.describe Export::JSON::Project, focus: true do

  def project_attributes
    attrs = Export::JSON::Project.project_attributes
    project.as_json.slice(*attrs).merge!(private: true)
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
      project_content: project_content_attributes,
      workflows: workflows_attributes,
      workflow_contents: workflow_content_attributes
    }.to_json
  end

  def export_values(object_key)
    JSON.parse(exporter.to_json)[object_key]
  end

  let(:project) { create(:project_with_workflows) }
  let(:project_content) { project.primary_content }
  let(:workflows) { project.workflows }
  let(:workflow_contents) { workflows.map(&:primary_content) }
  let(:exporter) { Export::JSON::Project.new(project.id) }

  describe "#to_json" do

    it 'return a export in the expected json format' do
      results = JSON.parse(exporter.to_json)
      expected = JSON.parse(export_json)
      expect(results).to eq(expected)
    end

    describe "project" do
      let(:new_project) { Project.new(export_values("project")) }

      it "should be able to rebuild a project from the export" do
        new_project.valid?
        expect(new_project.errors.keys).to match_array([:owner, :project_contents])
      end

      it "should be private by default" do
        expect(new_project.private).to eq(true)
      end
    end

    describe "project_content" do
      let(:new_project_content) do
        ProjectContent.new(export_values("project_content"))
      end

      it "should be able to rebuild a project_contents from the export" do
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
  end
end
