shared_examples "is destructable" do
  context "an authorized user" do
    before(:each) do
      stub_token(scopes: scopes, user_id: authorized_user.id)
      delete :destroy, id: resource.id
    end

    it "should return 204" do
      delete :destroy, id: resource.id
      expect(response.status).to eq(204)
    end

    it "should delete the resource" do
      delete :destroy, id: resource.id
      expect{resource_class.find(resource.id)}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "an unauthorized user" do
    before(:each) do
      unauthorized_user ||= create(:user)
      stub_token(scopes: scopes, user_id: unauthorized_user.id)
      delete :destroy, id: resource.id
    end

    it "should return 403" do
      expect(response.status).to eq(403)
    end

    it "should not have deleted the resource" do
      expect(resource_class.find(resource.id)).to eq(resource)
    end
  end
end
