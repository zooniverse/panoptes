shared_examples "roles validated" do
  it 'should be valid with a correct role' do
    instance = build(factory, { roles_field => [valid_roles.sample] })
    expect(instance).to be_valid
  end

  it 'should not be valid with a hopefully not valid role' do
    instance = build(factory, { roles_field => ["a_SDFJKAL_SDFKSJAAS__DSF"] })
    expect(instance).to_not be_valid
  end
end
