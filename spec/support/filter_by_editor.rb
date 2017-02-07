RSpec.shared_examples "filters by editor" do
  let(:collaborator) { create(:user) }
  let(:acl) do
    create(:access_control_list,
      resource: collab_resource,
      user_group: collaborator.identity_group,
      roles: ["collaborator"])
  end

  let(:index_options) do
    { editor: collaborator.login }
  end

  before do
    resource
    acl
    get :index, index_options
  end

  it "should respond with the correct number of items" do
    expect(json_response[api_resource_name].length).to eq(1)
  end

  it "should respond with the correct item" do
    # owner_id = json_response[api_resource_name][0]['links']['owner']['id']
    # expect(owner_id).to eq(resource.owner.id.to_s)
    expect(collab_resource.editors).to include collaborator.identity_group
  end

  context "when the editor name has a different case to the identity group" do
    let(:index_options) do
      resource
      { editor: [collaborator.login.upcase, 'SOMETHING'].join(',') }
    end

    it "should respond with the correct number of items" do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it "should respond with the correct item" do
      # owner_id = json_response[api_resource_name][0]['links']['owner']['id']
      # expect(owner_id).to eq(resource.owner.id.to_s)
      expect(collab_resource.editors).to include collaborator.identity_group
    end
  end
end
