RSpec.shared_examples "is showable" do
  let(:sps) do
    defined?(show_params) ? show_params : {}
  end

  before(:each) do
    default_request scopes: scopes, user_id: authorized_user.id
    get :show, params: sps.merge(id: resource.id)
  end

  it 'should return 200' do
    expect(response.status).to eq 200
  end

  it 'should have an ETag header' do
    expect(response.headers.key?('ETag')).to eq(true)
  end

  it 'should return the requested resource' do
    expect(json_response[api_resource_name].length).to eq 1
    expect(json_response[api_resource_name][0]['id']).to eq(resource.id.to_s)
  end

  it_behaves_like 'an api response'
end
