shared_examples "is indexable" do
  before(:each) do
    default_request scopes: scopes, user_id: authorized_user.id
    get :index
  end

  it 'should return 200' do
    expect(response.status).to eq 200
  end

  it "should have a specified number of items by default" do
    expect(json_response[api_resource_name].length).to eq n_visible
  end

  it 'should not include nonvisible resources' do
    resource_ids = json_response[api_resource_name]
      .collect{ |h| h['id'].to_i }
    expect(resource_ids).to_not include private_resource.id
  end

  it_behaves_like 'an api response'
end
