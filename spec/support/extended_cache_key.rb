shared_examples "has an extended cache key" do
  let(:stubbed_timestamp) { "20150511125031990014934" }
  let(:stubbed_resource_id) { 2 }
  let(:resource_class) { cached_resource.class }

  def resource_cache_key(resource)
    "#{resource.model_name.cache_key}/#{stubbed_resource_id}-#{stubbed_timestamp}"
  end

  def resource_association_instances
    cached_resource.class.included_associations.map do |assoc|
      cached_resource.send(assoc)
    end.flatten
  end

  def resource_associations
    associations
  rescue NameError
    []
  end

  def resource_methods
    methods
  rescue NameError
    []
  end

  describe "::cache_by_association" do
    it "should store the association key" do
      resource_class.cache_by_association(*resource_associations)
      expect(resource_class.included_associations)
        .to match_array(resource_associations)
    end
  end

  describe "::cache_by_resource_method" do
    it "should store the resource methods" do
      resource_class.cache_by_resource_method(*resource_methods)
      expect(resource_class.included_resource_methods)
        .to match_array(resource_methods)
    end
  end

  describe "#cache_key" do
    shared_examples "it should raise an error" do |method, result|
      it "should raise an error" do
        allow(cached_resource.class).to receive(method).and_return([result])
        expect {
          cache_key_result
        }.to raise_error(NoMethodError)
      end
    end

    let(:cache_key_result) { cached_resource.cache_key }

    context "when the class method name is invalid" do
      it_behaves_like "it should raise an error",
        :included_associations,
        :unknown_class_method
    end

    context "when the instance method name is invalid" do
      it_behaves_like "it should raise an error",
        :included_resource_methods,
        :unknown_instance_method
    end

    context "when no extra cache key directives are set" do

      before do
        %i(included_associations included_resource_methods).each do |cache_key|
          allow(cached_resource.class).to receive(cache_key).and_return([])
        end
      end

      it "should only include the resource cache key" do
        resource_cache_key = /#{cached_resource.model_name.cache_key}\/[\w-]+$/
        expect(cache_key_result).to match(resource_cache_key)
      end
    end

    # by default or else the model spec won't need the shared helpers
    context "when extra cache key directives are set" do

      before do
        resource_association_instances.each do |instance|
          stubbed_cache_key = resource_cache_key(instance)
          allow_any_instance_of(instance.class)
            .to receive(:cache_key)
            .and_return(stubbed_cache_key)
        end
      end

      it "should include the resource key" do
        expect(cache_key_result)
          .to match(/#{cached_resource.model_name.cache_key}\/\w+/)
      end

      it "should include the resource method key" do
        method_key = resource_methods.map do |method|
          Regexp.escape("#{method}:#{cached_resource.send(method)}")
        end.join
        expect(cache_key_result).to match(/#{method_key}/)
      end

      it "should include all the association keys" do
        resource_associations.map do |assocation|
          relation = cached_resource.send(assocation)
          relation_regex = /#{relation.model_name.cache_key}\/\w+/
          expect(cache_key_result).to match(relation_regex)
        end
      end
    end
  end
end
