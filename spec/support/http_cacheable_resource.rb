shared_examples "public resources http cache" do
  before(:each) do
    get action, query_params
  end

  it "should return 200" do
    expect(response.status).to eq(200)
  end

  it "should not have a default value" do
    expect(response.headers.key?("Cache-Control")).to be_falsey
  end

  context "with the http cache query param setup" do
    let(:query_params) { { http_cache: "true" } }

    it "should set the cache-control value" do
      expect(response.headers["Cache-Control"]).to eq("public max-age: 60")
    end
  end
end

shared_examples "private resources http cache" do
  before do
    private_resource
    get action, query_params
  end

  it "should return 200" do
    expect(response.status).to eq(200)
  end

  it "should not have a default value" do
    expect(response.headers["Cache-Control"]).to be_nil
  end
end

shared_examples "an authenticated http cacheable response" do
  let(:query_params) { { } }

  before do
    Panoptes.flipper["http_caching"].enable
  end

  it_behaves_like "private resources http cache" do
    context "with the http cache query param setup" do
      let(:query_params) { { http_cache: "true" } }

      it "should not have a cache directive value" do
        expect(response.headers["Cache-Control"]).to be_nil
      end
    end
  end

  it_behaves_like "public resources http cache"
end

shared_examples "an unauthenticated http cacheable response" do
  let(:query_params) { { } }

  before do
    Panoptes.flipper["http_caching"].enable
  end

  it_behaves_like "private resources http cache" do
    context "with the http cache query param setup" do
      let(:query_params) { { http_cache: "true" } }

      it "should not return the private resource in the response" do
        response_ids = created_instance_ids(api_resource_name)
        expect(response_ids).not_to include(private_resource.id.to_s)
      end

      it "should set the cache-control value" do
        expect(response.headers["Cache-Control"]).to eq("public max-age: 60")
      end
    end
  end

  it_behaves_like "public resources http cache"
end

shared_examples "is not a http cacheable response" do
  before do
    Panoptes.flipper["http_caching"].enable
  end

  context "for a public resource" do
    before(:each) do
      get action, params.merge(http_cache: "true")
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should not have a cache directive" do
      expect(response.headers["Cache-Control"]).to be_nil
    end
  end
end
