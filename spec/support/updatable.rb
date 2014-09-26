shared_examples "is updatable" do
  context "an authorized user" do
    let(:updated_resource) { resource.reload }
    
    before(:each) do
      default_request scopes: scopes, user_id: authorized_user.id
      params = update_params.merge(id: resource.id)
      put :update, params
    end
    
    it 'should update supplied attributes' do
      p updated_resource
      expect(updated_resource.send(test_attr)).to eq(test_attr_value)
    end

    it 'should return 200' do
      expect(response.status).to eq(200)
    end

    it_behaves_like 'an api response'
  end
  
  context "an unauthorized user" do
    before(:each) do
      user = if defined?(unauthorized_user)
               unauthorized_user
             else
               create(:user)
             end
      
      default_request scopes: scopes, user_id: user.id
      params = update_params.merge(id: resource.id)
      put :update, params
    end

    it 'should return 403' do
      expect(response.status).to eq(403)
    end

    it 'should not have modified the resource' do
      expect(resource_class.find(resource.id)).to eq(resource)
    end
  end
end

shared_examples "has updatable links" do
  let(:updated_resource) { resource.reload }
  
  before(:each) do
    default_request scopes: scopes, user_id: authorized_user.id
    params = update_params.merge(id: resource.id)
    put :update, params
  end
  
  it 'should update any included links' do
    expect(updated_resource.send(test_relation)
           .map(&:id)).to include(*test_relation_ids)
  end
end
