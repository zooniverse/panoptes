shared_examples "a panoptes restpack serializer" do |test_owner_include=false, test_blank_links=false|
  let(:scope) { resource.class.all }
  let(:test_link_serialization) { false }

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
      expect_any_instance_of(resource.class.const_get('ActiveRecord_Relation')).not_to receive(:preload)
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
      expect_any_instance_of(resource.class.const_get('ActiveRecord_Relation'))
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
      expect_any_instance_of(resource.class.const_get('ActiveRecord_Relation')).not_to receive(:preload)
      described_class.page({}, scope, {})
    end

    it "should handle preloading included relations" do
      expectation = includes.empty? ? :not_to : :to
      expect_any_instance_of(resource.class.const_get('ActiveRecord_Relation'))
        .send(expectation, receive(:preload))
        .with(*includes)
        .and_call_original
      described_class.page({include: includes.join(',')}, scope, {})
    end

    context "with owner include params" do
      if !!test_owner_include
        before do
          added_owner_includes = described_class.can_includes | %i(owners owner)
          allow(described_class)
          .to receive(:can_includes)
          .and_return(added_owner_includes)
        end

        %i(owners owner).each do |owner_include_variant|
          let(:params) do
            param_includes = (includes | [owner_include_variant]).join(',')
            { include: param_includes }
          end
          let(:expected_includes) do
            includes | [[ owner: { identity_membership: :user } ]]
          end

          it "should handle the special owner relation include param" do
            expect_any_instance_of(
              resource.class.const_get('ActiveRecord_Relation')
            ).to receive(:preload)
            .with(*expected_includes)
            .and_call_original
            described_class.page(params, scope, {})
          end
        end
      end
    end

    describe "link serialization" do
      if !!test_blank_links
        it "should include all link keys even if blank" do
          result_links = described_class.single({}, scope, {})[:links]
          expect(result_links.keys).to match_array(expected_links)
        end
      end
    end
  end
end
