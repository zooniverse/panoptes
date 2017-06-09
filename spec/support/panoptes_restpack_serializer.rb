shared_examples "a panoptes restpack serializer" do
  let(:scope) { resource.class.all }

  describe "preload associations" do
    around do |example|
      orig_values = described_class.instance_variable_get(:@preloads)
      example.run
      described_class.instance_variable_set(:@preloads, orig_values)
    end

    it "should match the serializer preloads" do
      serializer_preloads = described_class.preloads
      expect(serializer_preloads).to match_array(preloads)
    end

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
      expectation = preloads.empty? ? :not_to : :to
      expect_any_instance_of(resource.class::ActiveRecord_Relation)
        .send(expectation, receive(:preload))
        .with(*preloads)
        .and_call_original
      described_class.instance_variable_set(:@preloads, preloads)
      described_class.page({}, scope, {})
    end
  end

  describe "auto preload includes" do
    around do |example|
      orig_values = described_class.instance_variable_get(:@preloads)
      described_class.instance_variable_set(:@preloads, [])
      example.run
      described_class.instance_variable_set(:@preloads, orig_values)
    end

    it "should not preload when no included relations" do
      expect_any_instance_of(resource.class::ActiveRecord_Relation).not_to receive(:preload)
      described_class.page({}, scope, {})
    end

    it "should handle preloading included relations" do
      expectation = includes.empty? ? :not_to : :to
      expect_any_instance_of(resource.class::ActiveRecord_Relation)
        .send(expectation, receive(:preload))
        .with(*includes)
        .and_call_original
      described_class.page({include: includes.join(',')}, scope, {})
    end
  end
end
