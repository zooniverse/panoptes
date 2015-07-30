shared_examples "it only lists active resources" do

  it "should not include the deactivated_resource" do
    deactivated_ids = deactivated_resource.id
    get :index
    active_ids = created_instance_ids(api_resource_name)
    expect(active_ids).to_not include(deactivated_ids)
  end
end
