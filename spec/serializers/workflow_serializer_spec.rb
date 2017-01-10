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

  it "should not preload the serialized associations by default" do
    expect_any_instance_of(Workflow::ActiveRecord_Relation).not_to receive(:preload)
    WorkflowSerializer.page({}, Workflow.all, {})
  end

  it "should preload the serialized associations if enabled" do
    Panoptes.flipper["eager_load_workflows"].enable
    expect_any_instance_of(Workflow::ActiveRecord_Relation)
      .to receive(:preload)
      .with(*WorkflowSerializer::PRELOADS)
      .and_call_original
    WorkflowSerializer.page({}, Workflow.all, {})
  end

  describe "#tasks" do
    it 'should return the translated tasks' do
      expect(serializer.tasks['interest']['question']).to eq('Draw a circle')
    end
  end

  describe "#version" do
    it 'should be the current workflow and workflow content version number', :versioning do
      expected = "#{workflow.versions.last.index+1}.#{content.versions.last.index+1}"
      expect(serializer.version).to eq(expected)
    end
  end

  describe "#content_language" do
    it 'should return the language of the content being used' do
      expect(serializer.content_language).to eq("en")
    end
  end

  context "when there is no content_association" do
    let!(:workflow) do
      create(:workflow) do |workflow|
        workflow.workflow_contents = []
      end
    end

    it "should not have a content association" do
      expect(workflow.content_association).to be_empty
    end

    describe "#version", versioning: true do
      it "should use a 1 suffix for missing content versions" do
        version_num = workflow.versions.last.index + 1
        expect(serializer.version).to eq("#{version_num}.1")
      end
    end

    describe "#tasks" do

      it "should return an emtpy hash" do
        expect(serializer.tasks).to eq({})
      end
    end

    describe "#content_language" do

      it "should be nil" do
        expect(serializer.content_language).to be_nil
      end
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
end
