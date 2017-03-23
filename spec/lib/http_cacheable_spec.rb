require 'spec_helper'

describe HttpCacheable do
  let(:resource_name) { controlled_resources.klass.model_name }
  let(:resource) do
    factory_name = resource_name.singular.to_sym
    create(factory_name)
  end
  let(:http_cache) do
    HttpCacheable.new(controlled_resources)
  end

  def make_private(public_resource)
    public_resource.update_column(:private, true)
  end

  before do
    resource
  end

  describe '#public_resources?' do

    describe "a non-cacheable resource" do
      let(:controlled_resources) { Collection.all }

      it "should return false for a public resource" do
        expect(http_cache.public_resources?).to be false
      end

      it "should return false for a private resource" do
        make_private(resource)
        expect(http_cache.public_resources?).to be false
      end
    end

    describe "parental controlled resources" do
      let(:controlled_resources) { Subject.all }

      it "should return true with a public resource" do
        expect(http_cache.public_resources?).to be true
      end

      it "should return false with a private resource" do
        parent_relation = resource.class.parent_relation
        parent_resource = resource.send(parent_relation)
        make_private(parent_resource)
        expect(http_cache.public_resources?).to be false
      end
    end

    describe "controlled resources" do
      let(:controlled_resources) { Project.all }

      it "should return true with a public resource" do
        expect(http_cache.public_resources?).to be true
      end

      it "should return false with a private resource" do
        make_private(resource)
        expect(http_cache.public_resources?).to be false
      end
    end

    describe "#resource_cache_directive" do
      context "with a non-cacheable resource" do
        let(:controlled_resources) { Collection.all }

        it "should response with nil if not cacheable" do
          expect(http_cache.resource_cache_directive).to be_nil
        end
      end

      context "with a cacheable resource" do
        let(:controlled_resources) { Project.all }

        it "should response with the correct cache directive" do
          resource_key = resource_name.plural.to_sym
          cache_directive = HttpCacheable::CACHEABLE_RESOURCES[resource_key]
          expect(http_cache.resource_cache_directive).to eq(cache_directive)
        end
      end
    end
  end
end
