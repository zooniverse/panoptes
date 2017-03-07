shared_examples "favorited subjects" do
  it "creates a new FavoritesFinder instance" do
    allow_any_instance_of(FavoritesFinder)
       .to receive(:find_favorites).and_return([])
    expect_any_instance_of(FavoritesFinder)
      .to receive(:find_favorites)
    get :queued, request_params
  end
end
