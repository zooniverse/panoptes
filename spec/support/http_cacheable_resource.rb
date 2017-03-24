shared_examples "http cacheable response" do
  let(:query_params) { { } }

  context "for a private resource" do
    before do
      private_resource
      get :index, query_params
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
  end

  context "for a public resource" do
    before(:each) do
      get :index, query_params
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
end
