shared_examples "is public" do
  it "should permit admin users" do
    expect(subject).to permit(build(:admin_user), resource)
  end

  it "should permit logged in users" do
    expect(subject).to permit(build(:user), resource)
  end

  it "should permit logged-out users" do
    expect(subject).to permit(nil, resource)
  end
end

shared_examples "is public to logged in users" do
  it "should permit admin users" do
    expect(subject).to permit(build(:admin_user), resource)
  end

  it "should permit logged in users" do
    expect(subject).to permit(build(:user), resource)
  end

  it "should permit logged-out users" do
    expect(subject).to_not permit(nil, resource)
  end
end
