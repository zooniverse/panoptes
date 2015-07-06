shared_examples "is destructable" do
  let(:dps) do
    defined?(delete_params) ? delete_params : {}
  end

  context "an authorized user" do
    context "with proper scopes" do
      before(:each) do
        stub_token(scopes: scopes, user_id: authorized_user.id)
        set_preconditions
        delete :destroy, dps.merge!(id: resource.id)
      end

      it "should return 204" do
        expect(response).to have_http_status(:no_content)
      end

      it "should delete the resource" do
        expect{resource_class.find(resource.id)}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "without the correct token scope" do
      before(:each) do
        stub_token(scopes: ["public"], user_id: authorized_user.id)
        set_preconditions
        delete :destroy, dps.merge(id: resource.id)
      end

      it "should return forbidden with a non-scoped token" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "an unauthorized user" do
    before(:each) do
      user = if defined?(unauthorized_user)
               unauthorized_user
             else
               create(:user)
             end
      stub_token(scopes: scopes, user_id: user.id)
      set_preconditions
      delete :destroy, dps.merge(id: resource.id)
    end

    it "should return not found" do
      expect(response).to have_http_status(:not_found)
    end

    it "should not have deleted the resource" do
      expect(resource_class.find(resource.id)).to eq(resource)
    end
  end
end
