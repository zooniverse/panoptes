shared_context "a classification create" do
  it "should return 201" do
    create_classification
    expect(response.status).to eq(201)
  end

  it "should set the Location header as per JSON-API specs" do
    create_classification
    id = created_classification_id
    expect(response.headers["Location"]).to eq("http://test.host/api/classifications/#{id}")
  end

  it "should create the classification" do
    expect do
      create_classification
    end.to change{Classification.count}.from(0).to(1)
  end
end

shared_context "a classification lifecycle event" do

  let(:lifecycle ) { double }

  before(:each) do
    [ :update_cellect, :queue ].each do |stub|
      allow(lifecycle).to receive(stub)
    end
    allow(ClassificationLifecycle).to receive(:new).and_return(lifecycle)
  end

  it "should call the classification lifecycle update_cellect method" do
    expect(lifecycle).to receive(:update_cellect)
    create_classification
  end

  it "should call the classification lifecycle queue method" do
    expect(lifecycle).to receive(:queue).with(:create)
    create_classification
  end

  it "should set the user" do
    create_classification
    id = created_instance_id("classifications")
    expect(Classification.find(created_classification_id)
            .user.id).to eq(user.id)
  end
end

shared_context "a gold standard classfication" do

  context "when the gold standard flag is set to false" do
    let!(:gold_standard) { false }

    before(:each) do
      create_classification
    end

    it "should response with a 400" do
      expect(response.status).to eq(400)
    end

    it "should responsd with an error message in the body" do
      error_body = "Validation failed: Gold standard can not be set to false"
      expect(response.body).to eq(json_error_message(error_body))
    end
  end

  context "when the gold standard flag is set to true" do
    let!(:gold_standard) { true }

    before(:each) do
      create_classification
    end

    context "when the classifier is not an expert on the project" do

      it "should response with a 400" do
        expect(response.status).to eq(400)
      end

      it "should response with an error message in the body" do
        error_body = "Validation failed: Gold standard classifier is not a project expert"
        expect(response.body).to eq(json_error_message(error_body))
      end
    end

    context "when the classifier is an expert on the project" do
      let!(:user) { project.owner }

      it "should response with a 201" do
        expect(response.status).to eq(201)
      end
    end
  end
end
