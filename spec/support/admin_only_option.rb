RSpec.shared_examples 'admin only option' do |option, value|
  before(:each) do
    ps = create_params
    ps[:format] = :json
    ps[:admin] = true
    ps[:projects][option] = value
    default_request scopes: scopes, user_id: authorized_user.id
    post :create, ps
  end

  context "when the user is an admin" do
    let(:authorized_user) { create(:admin_user) }
    it "should create the project" do
      expect(response).to have_http_status(:created)
    end
  end

  context "when the user is not an admin" do
    let(:authorized_user) { create(:user) }
    it "should not create the project" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
