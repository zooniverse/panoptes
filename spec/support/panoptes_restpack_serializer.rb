shared_examples "a panoptes restpack serializer" do
  before do
    resource
  end

  it "should not preload when no included relations" do
    expect_any_instance_of(resource.class::ActiveRecord_Relation).not_to receive(:preload)
    described_class.page({}, Workflow.all, {})
  end

  it "should preload included relations" do
    expect_any_instance_of(resource.class::ActiveRecord_Relation)
      .to receive(:preload)
      .with(*preloads)
      .and_call_original
    described_class.page({include: includes}, Workflow.all, {})
  end
end
