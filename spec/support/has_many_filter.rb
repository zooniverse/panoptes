RSpec.shared_examples "has many filterable" do |relation|
  let(:resource_relation_id) { filtered_resources.first.send(relation).first.id.to_s }
  let(:filtered_ids) { filtered_resources.map { |r| r.id.to_s } }
  let(:filter_params)  { { "#{relation.to_s.singularize}_id" => resource_relation_id } }

  it "should be filtered by the resource's relation id" do
    get :index, filter_params
    expect(created_instance_ids(api_resource_name)).to match_array(filtered_ids)
  end
end
