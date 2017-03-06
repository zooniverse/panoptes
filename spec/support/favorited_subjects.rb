shared_examples "favorited subjects" do
  let(:fav_subject) { subjects.last }
  let!(:collection) do
    create(:collection, owner: user, subjects: [fav_subject], favorite: true, projects: [workflow.project])
  end
  context "user has no favorites" do
    it "returns favorite as false" do
      user.collections.destroy_all
      get :queued, request_params
      favorites = json_response["subjects"].map{ |s| s['favorite']}
      expect(favorites).to all( be false )
    end
  end

  context "user has favorites" do
    before(:each) { get :queued, request_params }

    it "favorite returns true for favorited subjects" do
      fav = json_response["subjects"].find{ |s| s["id"] == fav_subject.id.to_s }
      expect(fav["favorite"]).to be true
    end

    it "favorite returns false for non-favorited subjects" do
      fav = json_response["subjects"].find{ |s| s["id"] != fav_subject.id.to_s }
      expect(fav["favorite"]).to be false
    end
  end

  context "not logged in" do
    it "returns favorites as false" do
      default_request
      get :queued, request_params
      favorites = json_response["subjects"].map{ |s| s['favorite']}
      expect(favorites).to all( be false )
    end
  end
end