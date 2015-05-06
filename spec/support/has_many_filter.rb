RSpec.shared_examples "has many filterable" do |relation|
  let(:filtered_resource) { filterable_resources.first }
  let(:relation_filter_id) { filtered_resource.send(relation).first.id.to_s }
  let(:filter_params)  { { "#{relation.to_s.singularize}_id" => relation_filter_id } }

  it "should be filtered by the resource's relation id" do
    get :index, filter_params
    expect(created_instance_ids(api_resource_name)).to match_array(expected_filtered_ids)
  end
end
