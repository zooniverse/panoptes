shared_examples "is indexable" do
  let(:resource_ids) do
    created_instance_ids(api_resource_name).map(&:to_i)
  end

  context 'for a normal user' do
    before(:each) do
      default_request scopes: scopes, user_id: authorized_user.id if authorized_user
      get :index
    end

    it 'should return 200', :focus do
      expect(response.status).to eq 200
    end

    it "should have a specified number of items by default" do
      expect(json_response[api_resource_name].length).to eq n_visible
    end

    it 'should not include nonvisible resources' do
      expect(resource_ids).to_not include private_resource.id
    end

    it_behaves_like 'an api response'
  end

  context 'when the authorized_user is an admin' do
    let(:authorized_user) { create(:user, admin: true) }

    context 'when an admin param is set' do
      it 'should include the non-visible resource' do
        default_request scopes: scopes, user_id: authorized_user.id if authorized_user
        get :index, admin: 'literally_anything!'

        expect(resource_ids).to include private_resource.id
      end
    end

    context 'when no admin param is set' do
      it 'should not include the non-visible resource' do
        default_request scopes: scopes, user_id: authorized_user.id if authorized_user
        get :index

        expect(resource_ids).to_not include private_resource.id
      end
    end
  end
end
