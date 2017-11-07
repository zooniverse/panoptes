shared_examples "taggable" do
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
