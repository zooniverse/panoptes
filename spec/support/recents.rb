RSpec.shared_examples "has recents" do
  let!(:classifications) do
    [create(:classification_with_recents, created_at: 1.hour.ago, resource_key => resource ),
      create(:classification_with_recents, resource_key => resource )]
  end

  let(:links) { recent_json.map{|r| r['links']} }
  let(:recent_json) { json_response['recents'] }

  describe "#recents"
  before(:each) do
    default_request(scopes: scopes, user_id: authorized_user.id)
    get :recents, filter_params.merge(resource_key_id => resource.id)
  end

  context "no filters" do
    let(:filter_params) { {} }
    it 'should respond ok' do
      expect(response).to have_http_status(:ok)
    end

    it 'should have recently classified subjects' do
      expect(recent_json.length).to eq(4)
    end

    it 'should have a link to the project and workflow' do
      expect(links).to all( include('project', 'workflow') )
    end

    it 'should have a locations hash' do
      expect(recent_json).to all( include('locations') )
    end
  end

  context "sorted by created_at asc" do
    let(:filter_params) { {sort: "+created_at" } }

    it 'should be sorted by created_at in ascending order' do
      expect(recent_json.map{ |r| r['id'].to_i }).to match_array(Recent.order(created_at: :asc).pluck(:id))
    end
  end

  context "sorted by created_at desc" do
    let(:filter_params) { {sort: "-created_at" } }

    it 'should be sorted by created_at in descending order' do
      expect(recent_json.map{ |r| r['id'].to_i }).to match_array(Recent.order(created_at: :desc).pluck(:id))
    end
  end

  context "filtered by project" do
    let(:filter_params) { {project_id: classifications.first.project.id.to_s} }
    it 'should be filterable' do
      expect(recent_json.length).to eq(2)
    end

    it 'should all have the same project_id' do
      expect(links.map{ |l| l['project'] }).to all( eq(classifications.first.project.id.to_s))
    end
  end

  context "filtered by workflow" do
    let(:filter_params) { {workflow_id: classifications.first.workflow.id.to_s} }
    it 'should be filterable' do
      expect(recent_json.length).to eq(2)
    end

    it 'should all have the same workflow_id' do
      expect(links.map{ |l| l['workflow'] }).to all( eq(classifications.first.workflow.id.to_s))
    end
  end
end
