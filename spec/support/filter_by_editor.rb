RSpec.shared_examples "filters by editor" do
  # let(:expected_count) { collab_resource.count }
  let(:expected_count) { 1 }

  let(:collaborator) { create(:user) }
  let(:acl) do
    create(:access_control_list,
      resource: collab_collection,
      user_group: collaborator.identity_group,
      roles: ["collaborator"])
  end

  let(:index_options) do
    { editor: collaborator.login }
  end

  before do
    resource
    get :index, index_options
  end

  it "should respond with the correct number of items" do
    expect(json_response[api_resource_name].length).to eq(expected_count)
  end

  xit "should respond with the correct item" do
    owner_id = json_response[api_resource_name][0]['links']['owner']['id']
    expect(owner_id).to eq(resource.owner.id.to_s)
  end

  context "when the owner name has a different case to the identity group" do
    let(:index_options) do
      resource
      { owner: [owner.login.upcase, 'SOMETHING'].join(',') }
    end

    xit "should respond with the correct number of items" do
      expect(json_response[api_resource_name].length).to eq(expected_count)
    end

    xit "should respond with the correct item" do
      owner_id = json_response[api_resource_name][0]['links']['owner']['id']
      expect(owner_id).to eq(resource.owner.id.to_s)
    end
  end
end
