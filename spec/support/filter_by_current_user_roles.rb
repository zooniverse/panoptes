RSpec.shared_examples "filters by current user roles" do
  let(:role_filter_resources) { owner_resources | [ collab_resource ] }
  let(:index_options) do
    { current_user_roles: 'owner,collaborator' }
  end
  let(:response_ids) { json_response[api_resource_name].map{ |p| p['id'] } }

  before do
    owner_resources
    { viewer_resource => "viewer", collab_resource => "collaborator" }.each do |obj, role|
      create(:access_control_list,
             resource: obj,
             user_group: authorized_user.identity_group,
             roles: [role])
    end
    default_request scopes: scopes, user_id: authorized_user.id
  end

  it "should respond with the correct number of role items" do
    get :index, params: index_options
    expect(json_response[api_resource_name].length).to eq(role_filter_resources.size)
  end

  it "should work with Rails style array params" do
    index_options[:current_user_roles] = ["owner", "collaborator"]
    get :index, params: index_options
    expect(json_response[api_resource_name].length).to eq(role_filter_resources.size)
  end

  it 'should not include the resource id when the user has a different role' do
    get :index, params: index_options
    expect(response_ids).to_not include(viewer_resource.id.to_s)
  end

  it "should respond with the correct items" do
    get :index, params: index_options
    filtered_ids = role_filter_resources.map(&:id).map(&:to_s)
    expect(response_ids).to include(*filtered_ids)
  end

  context "with just the owner role filter" do
    let(:index_options) { { current_user_roles: 'owner' } }

    it "should respond with the correct number of owner items" do
      get :index, params: index_options
      expect(json_response[api_resource_name].length).to eq(owner_resources.count)
    end
  end
end
