shared_examples "public resources http cache" do
  it "should return 200" do
    expect(response.status).to eq(200)
  end

  it "should not have a default value" do
    expect(response.headers.key?("Cache-Control")).to be_falsey
  end

  context "with the http cache query param setup" do
    let(:cache_params) { { http_cache: "true" } }

    it "should set the cache-control value" do
      expect(response.headers["Cache-Control"]).to eq("public max-age: 60")
    end
  end
end

shared_examples "private resources http cache" do
  it "should return 200" do
    expect(response.status).to eq(200)
  end

  it "should not have a default value" do
    expect(response.headers["Cache-Control"]).to be_nil
  end

  context "with the http cache query param setup" do
    let(:cache_params) { { http_cache: "true" } }

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should not have a cache-control value" do
      expect(response.headers["Cache-Control"]).to be_nil
    end
  end
end

shared_examples "an indexable authenticated http cacheable response" do
  let(:query_params) { { } }

  before do
    default_request user_id: user.id, scopes: scopes
    get action, query_params
  end

  it "should return 200" do
    expect(response.status).to eq(200)
  end

  it "should not have a default value" do
    expect(response.headers["Cache-Control"]).to be_nil
  end

  context "with the http cache query param setup" do
    let(:query_params) { { http_cache: "true" } }

    it "should not have a cache directive value" do
      expect(response.headers["Cache-Control"]).to be_nil
    end
  end

  it_behaves_like "public resources http cache"
end

shared_examples "an indexable unauthenticated http cacheable response" do
  let(:query_params) { { } }

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

shared_examples "an showable authenticated http cacheable response" do
  let(:cache_params) { { } }

  before do
    default_request user_id: user.id, scopes: scopes
    get action, query_params.merge(cache_params)
  end

  it_behaves_like "private resources http cache" do
    let(:query_params) { { id: private_resource_id } }
  end

  it_behaves_like "public resources http cache" do
    let(:query_params) { { id: public_resource_id } }
  end
end

shared_examples "an showable unauthenticated http cacheable response" do
  let(:cache_params) { { } }

  before do
    get action, query_params.merge(cache_params)
  end

  context "when trying to access a private resource" do
    let(:query_params) { { id: private_resource_id } }

    it "should return 404" do
      expect(response.status).to eq(404)
    end

    it "should not have a cache value" do
      expect(response.headers["Cache-Control"]).to be_nil
    end
  end

  it_behaves_like "public resources http cache" do
    let(:query_params) { { id: public_resource_id } }
  end
end

shared_examples "is not a http cacheable response" do

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
