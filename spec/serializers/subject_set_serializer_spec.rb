require 'spec_helper'

describe SubjectSetSerializer do
  let(:subject_set) { create(:subject_set) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { subject_set }
    let(:includes) { %i(project workflows) }
    let(:preloads) { %i(workflows) }
  end

  it_should_behave_like "a filter has many serializer" do
    let(:resource) { subject_set }
    let(:relation) { :workflows }
    let(:next_page_resource) do
      create(:subject_set, workflows: subject_set.workflows)
    end
  end
end
