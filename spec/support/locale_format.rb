shared_examples "a locale field" do
  it "should require languages to be exactly 2 or 5 characters" do
    expect(build(factory, locale_field => 'a')).to_not be_valid
    expect(build(factory, locale_field => 'abasdf')).to_not be_valid
  end

  it "should require languages to conform to a format" do
    expect(build(factory, locale_field => 'abasd')).to_not be_valid
    expect(build(factory, locale_field => 'ab')).to be_valid
    expect(build(factory, locale_field => 'ab-sd')).to be_valid
  end
end
