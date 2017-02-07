RSpec.shared_examples "filters by editor" do
  let(:collaborator) { create(:user) }
  let(:acl) do
    create(:access_control_list,
      resource: collab_resource,
      user_group: collaborator.identity_group,
      roles: ["collaborator"])
  end

  let(:private_acl) do
    create(:access_control_list,
      resource: private_resource,
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
    expect(collab_resource.editors).to include collaborator.identity_group
  end

  it "should not include private collections" do
    expect(json_response[api_resource_name].map { |c| c["id"] })
      .to_not include private_resource.id.to_s
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
      expect(collab_resource.editors).to include collaborator.identity_group
    end
  end
end
