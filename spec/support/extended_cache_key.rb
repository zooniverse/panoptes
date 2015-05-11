shared_examples "has an extended cache key" do |associations, resource_methods|

  let(:stubbed_timestamp) { "20150511125031990014934" }
  let(:stubbed_resource_id) { 2 }

  def resource_cache_key(resource)
    "#{resource.model_name.cache_key}/#{stubbed_resource_id}-#{stubbed_timestamp}"
  end

  def resource_association_instances
    cached_resource.class.included_associations.map do |assoc|
      cached_resource.send(assoc)
    end.flatten
  end

  let(:resource_class) { cached_resource.class }

  describe "::cache_by_association" do

    it "should store the association key" do
      resource_class.cache_by_association(*associations)
      expect(resource_class.included_associations).to match_array(associations)
    end
  end

  describe "::cache_by_resource_method" do

    it "should store the resource methods" do
      resource_class.cache_by_resource_method(*resource_methods)
      expect(resource_class.included_resource_methods).to match_array(resource_methods)
    end
  end

  describe "#cache_key" do
    let(:cache_key_result) { cached_resource.cache_key }

    context "when no extra cache key directives are set" do

      before(:each) do
        %i(included_associations included_resource_methods).each do |cache_key|
          allow(cached_resource.class).to receive(cache_key).and_return([])
        end
      end

      it "should only include the resource cache key" do
        resource_cache_key = /#{cached_resource.model_name.cache_key}\/\w+$/
        expect(cache_key_result).to match(resource_cache_key)
      end
    end

    # by default or else the model spec won't need the shared helpers
    context "when extra cache key directives are set" do

      before(:each) do
        resource_association_instances.each do |instance|
          stubbed_cache_key = resource_cache_key(instance)
          allow_any_instance_of(instance.class).to receive(:cache_key).and_return(stubbed_cache_key)
        end
      end

      it "should include the resource key" do
        expect(cache_key_result).to match(/#{cached_resource.model_name.cache_key}\/\w+/)
      end

      it "should include the resource method key" do
        method_key = resource_methods.map do |method|
          Regexp.escape("#{method}:#{cached_resource.send(method)}")
        end.join
        expect(cache_key_result).to match(/#{method_key}/)
      end

      it "should include all the association keys" do
        assoc_regex = cached_resource.send(*associations).map do |relation|
          expect(cache_key_result).to match(/#{relation.model_name.cache_key}\/\w+/)
        end
      end
    end
  end
end
