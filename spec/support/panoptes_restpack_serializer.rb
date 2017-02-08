shared_examples "a panoptes restpack serializer" do
  let(:scope) { resource.class.all }

  describe "preload associations" do
    it "should not preload when none set" do
      expect_any_instance_of(resource.class::ActiveRecord_Relation).not_to receive(:preload)
      described_class.instance_variable_set(:@preloads, [])
      described_class.page({}, scope, {})
    end

    it "should raise an error if invalid preloads" do
      described_class.instance_variable_set(:@preloads, [:invalid])
      expect {
        described_class.page({}, scope, {})
      }.to raise_error(ActiveRecord::AssociationNotFoundError)
    end

    it "should preload valid preloads" do
      expect_any_instance_of(resource.class::ActiveRecord_Relation)
        .to receive(:preload)
        .with(*preloads)
      described_class.instance_variable_set(:@preloads, preloads)
      described_class.page({}, scope, {})
    end
  end

  describe "auto preload includes" do
    before do
      described_class.instance_variable_set(:@preloads, [])
    end

    it "should not preload when no included relations" do
      expect_any_instance_of(resource.class::ActiveRecord_Relation).not_to receive(:preload)
      described_class.page({}, scope, {})
    end

    it "should preload included relations" do
      expect_any_instance_of(resource.class::ActiveRecord_Relation)
        .to receive(:preload)
        .with(*preloads)
      described_class.page({include: includes}, scope, {})
    end
  end
end
