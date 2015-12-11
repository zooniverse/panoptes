shared_examples 'is deactivatable' do
  context "an authorized user" do
    context "with correct scopes" do
      before(:each) do
        stub_token(scopes: scopes, user_id: authorized_user.id)
        set_preconditions
      end

      it "should call Activation#disable_instances! with instances to disable" do
        expect(Activation).to receive(:disable_instances!).with(instances_to_disable)
        delete :destroy, id: resource.id
      end

      it "should return no content" do
        delete :destroy, id: resource.id
        expect(response).to have_http_status(:no_content)
      end

      it "should disable the resource" do
        delete :destroy, id: resource.id
        expect(resource.reload.inactive?).to be_truthy
      end
    end

    context "with incorrect scopes" do
      before(:each) do
        stub_token(scopes: ["public"], user_id: authorized_user.id)
        set_preconditions
        delete :destroy, id: resource.id
      end

      it "should 403 with a non-scoped token" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "an unauthorized user" do
    before(:each) do
      unauthorized_user ||= create(:user)
      stub_token(scopes: scopes, user_id: unauthorized_user.id)
      set_preconditions
    end

    it "should return not found" do
      delete :destroy, id: resource.id
      expect(response).to have_http_status(:not_found)
    end

    it "should not disable the resource" do
      delete :destroy, id: resource.id
      expect(resource.reload.inactive?).to be_falsy
    end
  end
end
