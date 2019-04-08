require 'spec_helper'

describe WorkflowSerializer do
  let(:workflow) { create(:workflow) }
  let(:serializer) do
    serializer = WorkflowSerializer.new
    serializer.instance_variable_set(:@model, workflow)
    serializer.instance_variable_set(:@context,
                                     {languages: ['en']})
    serializer
  end

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { workflow }
    let(:includes) { %i(project subject_sets tutorial_subject) }
    let(:preloads) do
      %i(subject_sets attached_images classifications_export published_version)
    end
  end

  it_should_behave_like "a filter has many serializer" do
    let(:resource) { create(:workflow_with_subject_set) }
    let(:relation) { :subject_sets }
    let(:next_page_resource) do
      create(:workflow, subject_sets: resource.subject_sets)
    end
  end

  describe "#tasks" do
    it 'should return the translated tasks' do
      expect(serializer.tasks['interest']['question']).to eq('Draw a circle')
    end

    it 'uses published strings when requested' do
      workflow.publish!
      workflow.strings["interest.question"] = "Draw a round thing"
      workflow.save!

      serializer.instance_variable_set(:@context, {languages: ['en'], published: true})
      expect(serializer.tasks['interest']['question']).to eq('Draw a circle')
    end
  end

  describe "#version" do
    it 'should be the current workflow and workflow content version number', :versioning do
      expected = "#{workflow.major_version}.#{workflow.minor_version}"
      expect(serializer.version).to eq(expected)
    end
  end

  describe "#content_language" do
    it 'should return the language of the content being used' do
      expect(serializer.content_language).to eq("en")
    end
  end

  describe "#retirement" do
    let(:expected) { serializer.retirement }

    context "with no values set" do
      it 'should return the default criteria' do
        defaults = Workflow::DEFAULT_RETIREMENT_OPTIONS
        expect(expected).to eq(defaults)
      end
    end

    context "with values set" do
      let(:custom) do
        Workflow::DEFAULT_RETIREMENT_OPTIONS.merge("options" => {count: 5})
      end

      it 'should return the stored values' do
        allow_any_instance_of(Workflow).to receive(:retirement).and_return(custom)
        expect(expected).to eq(custom)
      end
    end
  end

  describe "#page_size" do
    let(:scope) { Workflow.where(id: workflow.id) }
    let(:params) {{ page_size: 50 }}

    it "should default to the max model limit" do
      result = WorkflowSerializer.page(params, scope)
      page_size = result.dig(:meta, :workflows, :page_size)
      expect(page_size).to eq(25)
    end
  end
end
