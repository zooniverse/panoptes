shared_context "indexable by tag" do
  describe "tag filters" do
    let!(:tags) do
      [create(:tag, name: "youreit", resource: resource),
       create(:tag, name: "youreout", resource: second_resource)]
    end
    let(:tag) { tags.first }

    before do
      get :index, index_options
    end

    describe "fuzzy filter by tag name" do
      context "with full tag" do
        let(:index_options) { { search: "tag:#{tag.name}" } }

        it 'should return a project with the tag' do
          expect(json_response[api_resource_name][0]["id"]).to eq(resource.id.to_s)
        end
      end

      context "partial tag" do
        let(:index_options) { { search: "tag:#{tag.name[0..-4]}" } }

        it 'should fuzzymatch' do
          expect(json_response[api_resource_name].map{ |p| p["id"]}).to match_array([resource.id.to_s, second_resource.id.to_s])
        end
      end
    end

    describe "strict filter by tag" do
      context "with full tag" do
        let(:index_options) { { tags: tag.name } }

        it 'should return a project with the tag' do
          expect(json_response[api_resource_name][0]["id"]).to eq(resource.id.to_s)
        end
      end

      context "case insensitive" do
        let(:index_options) { { tags: tag.name.upcase } }

        it 'should return a project with the tag' do
          expect(json_response[api_resource_name][0]["id"]).to eq(resource.id.to_s)
        end
      end

      context "partial tag" do
        let(:index_options) { { tags: tag.name[0..-4] } }

        it 'should return nothing' do
          expect(json_response[api_resource_name]).to be_empty
        end
      end
    end
  end
end

shared_context "has updatable tags" do
  describe "updates tags" do
    def tag_update
      default_request scopes: scopes, user_id: authorized_user.id
      put :update, tag_params
    end

    it 'should remove all previous tags' do
      create(:tag, name: "GONE", resource: resource)
      tag_update
      resource.reload
      expect(resource.tags.pluck(:name)).to_not include("GONE")
    end

    it 'should update with new tags' do
      tag_update
      resource.reload
      expect(resource.tags.pluck(:name)).to match_array(tag_array)
    end

    it "should touch the resource to modify the cache_key / etag" do
      expect {
        tag_update
      }.to change { resource.reload.updated_at }
    end
  end
end
