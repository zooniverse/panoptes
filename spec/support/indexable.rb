RSpec.shared_examples "is indexable" do |private_test=true|
  let(:resource_ids) do
    created_instance_ids(api_resource_name).map(&:to_i)
  end

  let(:ips) do
    defined?(index_params) ? index_params : {}
  end

  context 'for a normal user' do
    before(:each) do
      default_request scopes: scopes, user_id: authorized_user.id if authorized_user
      get :index, ips
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it "should have a specified number of items by default" do
      expect(json_response[api_resource_name].length).to eq n_visible
    end

    if private_test
      it 'should not include nonvisible resources' do
        expect(resource_ids).to_not include private_resource.id
      end
    end

    it_behaves_like 'an api response'
    it_behaves_like 'an indexable etag response'
  end

  if private_test
    context 'when the authorized_user is an admin' do
      let(:authorized_user) { create(:user, admin: true) }

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id if authorized_user
      end

      context 'when an admin param is set' do
        it 'should include the non-visible resource' do
          get :index, ips.merge(admin: 'literally_anything!')
          expect(resource_ids).to include private_resource.id
        end
      end

      context 'when no admin param is set' do
        it 'should not include the non-visible resource' do
          get :index, ips
          expect(resource_ids).to_not include private_resource.id
        end
      end
    end
  end
end
