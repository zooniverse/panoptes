RSpec.shared_examples "has recents" do
  let!(:classifications) do
    create_list(:classification, 2, resource_key => resource )
  end
  
  let(:links) { json_response['recents'].map{|r| r['links']} }
  
  before(:each) do
    default_request(scopes: scopes, user_id: authorized_user.id)
    get :recents, resource_key_id => resource.id
  end

  it 'should respond ok' do
    expect(response).to have_http_status(:ok)
  end

  it 'should have recently classified subjects' do
    expect(json_response['recents'].length).to eq(4)
  end

  it 'should have a link to the project and workflow' do
    expect(links).to all( include('project', 'workflow') )
  end

  it 'should have a locations hash' do
    expect(json_response['recents']).to all( include('locations') )
  end
end
