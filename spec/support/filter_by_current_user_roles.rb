RSpec.shared_examples "filters by current user roles" do
  let(:index_options) do
    { current_user_roles: 'owner,collaborator' }
  end
  let(:collab_acls) do
    create(:access_control_list,
           resource: role_filter_resource,
           user_group: role_filter_user.identity_group,
           roles: ["viewer"])
    create(:access_control_list,
           resource: resource,
           user_group: role_filter_user.identity_group,
           roles: ["collaborator"])
  end
  let(:response_ids) { json_response[api_resource_name].map{ |p| p['id'] } }

  before(:each) do
    collab_acls
    get :index, index_options
  end

  it "should respond with 3 items" do
    expect(json_response[api_resource_name].length).to eq(3)
  end

  it 'should not have a project where the user has a different role' do
    expect(response_ids).to_not include(beta_resource.id.to_s)
  end

  it "should respond with the correct item" do
    expect(response_ids).to include(new_project.id.to_s, *projects.map(&:id).map(&:to_s))
  end

  context "with just the owner role filter" do
    let(:index_options) { { current_user_roles: 'owner' } }

    it "should respond with 2 items" do
      expect(json_response[api_resource_name].length).to eq(2)
    end
  end
end
