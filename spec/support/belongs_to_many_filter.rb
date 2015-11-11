RSpec.shared_examples "belongs to many filterable" do |relation|
  let(:filtered_resource) { filterable_resources.first }
  let(:filter_params)  { { "#{relation.to_s.singularize}_ids" => filter_ids } }

  it "should be filtered by the resource's relation ids" do
    get :index, filter_params
    expect(created_instance_ids(api_resource_name)).to match_array(expected_filtered_ids)
  end
end
