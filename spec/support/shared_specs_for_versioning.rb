RSpec.shared_examples "a versioned model" do
  let(:factory_name) { described_class.to_s.underscore }
  let(:model) { create(factory_name) }
  let(:versioned_attribute) { model.class.versioned_attributes.first }
  let(:new_value) { "foo" }

  it 'creates a version when the model is inserted initially' do
    expect(model.send(model.class.versioned_association).count).to eq(1)
  end

  it 'creates a version if an attribute that is under version control changes' do
    expect do
      model.assign_attributes(versioned_attribute => new_value)
      model.save!
    end.to change { model.send(model.class.versioned_association).count }.by(1)
  end
end
