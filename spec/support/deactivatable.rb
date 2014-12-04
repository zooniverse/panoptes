shared_examples 'is deactivatable' do
  context "an authorized user" do
    before(:each) do
      stub_token(scopes: scopes, user_id: authorized_user.id)
    end

    it "should call Activation#disable_instances! with instances to disable" do
      expect(Activation).to receive(:disable_instances!).with(instances_to_disable)
      delete :destroy, id: resource.id
    end

    it "should return 204" do
      delete :destroy, id: resource.id
      expect(response.status).to eq(204)
    end

    it "should disable the resource" do
      delete :destroy, id: resource.id
      expect(resource.reload.inactive?).to be_truthy
    end

    it "should 403 with a non-scoped token" do
      stub_token(scopes: ["public"], user_id: authorized_user.id)
      delete :destroy, id: resource.id
      expect(response.status).to eq(403)
    end
  end

  context "an unauthorized user" do
    before(:each) do
      unauthorized_user ||= create(:user)
      stub_token(scopes: scopes, user_id: unauthorized_user.id)
    end

    it "should return 403" do
      delete :destroy, id: resource.id
      expect(response.status).to eq(403)
    end

    it "should not disable the resource" do
      delete :destroy, id: resource.id
      expect(resource.reload.inactive?).to be_falsy
    end
  end
end
