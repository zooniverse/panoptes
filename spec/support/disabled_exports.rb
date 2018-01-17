shared_examples "it forbids data exports" do
  context "when the project resource has exports disabled" do
    before do
      private_data_config = project.configuration.merge("private_data" => true)
      project.update_column(:configuration, private_data_config)
    end

    it 'throws a forbidden error with a useful message' do
      default_request scopes: scopes, user_id: authorized_user.id
      post :create_classifications_export, create_params
      expect(json_response['errors'][0]['message'])
        .to eq("Data exports are disabled for this project")
      expect(response.status).to eq(403)
    end
  end
end
