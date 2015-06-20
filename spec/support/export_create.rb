RSpec.shared_examples "export create" do |export_worker, export_type|
  let(:create_path) { "create_#{export_type}"}

  it 'should queue an export worker' do
    expect(export_worker).to receive(:perform_async).with(resource.id, an_instance_of(Fixnum))
    default_request scopes: scopes, user_id: user.id
    post create_path, create_params
  end

  it 'should add the current user to the recipients list if none are specified' do
    params = create_params
    params[:media].delete(:metadata)
    default_request scopes: scopes, user_id: user.id
    post create_path, params
    expect(resource.send(export_type).metadata).to include("recipients" => [authorized_user.id])
  end

  it 'should update an existing export if one exists' do
    params = create_params
    params[:media].delete(:metadata)
    export = create(:medium, linked: resource, type: "project_#{export_type}", content_type: "text/csv", metadata: {})
    default_request scopes: scopes, user_id: user.id
    post create_path, params
    export.reload
    expect(export.metadata).to include("recipients" => [authorized_user.id])
  end
end
