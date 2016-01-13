shared_context "a classification create" do
  it "should return 201" do
    create_action
    expect(response).to have_http_status(:created)
  end

  it "should call the classification lifecycle from the yield block" do
    expect(controller).to receive(:lifecycle).with(:create, anything)
    create_action
  end

  it "should set the Location header as per JSON-API specs" do
    create_action
    id = created_classification_id
    expect(response.headers["Location"]).to eq("http://test.host/api/classifications/#{id}")
  end

  it "should set the workflow_version field from the metadata" do
    create_action
    expect(Classification.find(created_classification_id).workflow_version).to eq("1.1")
  end

  it "should set the user correctly" do
    create_action
    c = Classification.find(created_instance_id("classifications"))
    expect(c.user_id).to eq(user.try(:id))
  end

  it "should create the classification" do
    expect do
      create_action
    end.to change{Classification.count}.from(0).to(1)
  end
end

shared_context "a classification lifecycle event" do

  let(:lifecycle ) { double(dequeue_subjects: nil) }

  before(:each) do
    [ :queue ].each do |stub|
      allow(lifecycle).to receive(stub)
    end
    allow(ClassificationLifecycle).to receive(:new).and_return(lifecycle)
  end

  it "should call the classification lifecycle queue method" do
    expect(lifecycle).to receive(:queue).with(:create)
    create_action
  end
end

shared_context "a gold standard classfication" do

  context "when the gold standard flag is set to false" do
    let!(:gold_standard) { false }

    before(:each) do
      create_action
    end

    it "should respond with bad request" do
      expect(response).to have_http_status(:bad_request)
    end

    it "should responsd with an error message in the body" do
      error_body = "Validation failed: Gold standard can not be set to false"
      expect(response.body).to eq(json_error_message(error_body))
    end
  end

  context "when the gold standard flag is set to true" do
    let!(:gold_standard) { true }

    before(:each) do
      create_action
    end

    context "when the classifier is not an expert on the project" do

      it "should respond with bad request" do
        expect(response).to have_http_status(:bad_request)
      end

      it "should response with an error message in the body" do
        error_body = "Validation failed: Gold standard classifier is not a project expert"
        expect(response.body).to eq(json_error_message(error_body))
      end
    end

    context "when the classifier is an expert on the project" do
      let!(:user) { project.owner }

      it "should respond with created" do
        expect(response).to have_http_status(:created)
      end
    end
  end
end
