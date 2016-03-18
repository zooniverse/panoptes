require 'spec_helper'

shared_examples "cleans up the linked set member subjects" do

  it 'should remove the linked set_member_subjects' do
    delete_resources
    expect(SetMemberSubject.where(id: linked_sms_ids)).to be_empty
  end

  it 'should queue a count reset worker' do
    expect(CountResetWorker).to receive(:perform_async).with(subject_set.id)
    delete_resources
  end

end

describe Api::V1::SubjectSetsController, type: :controller do
  let!(:subject_sets) { create_list :subject_set_with_subjects, 2 }
  let(:subject_set) { subject_sets.first }
  let(:project) { subject_set.project }
  let(:owner) { project.owner }
  let(:api_resource_name) { 'subject_sets' }

  let(:api_resource_attributes) do
    %w(id display_name set_member_subjects_count created_at updated_at metadata)
  end
  let(:api_resource_links) { %w(subject_sets.project subject_sets.workflows) }

  let(:scopes) { %w(public project) }
  let(:resource_class) { SubjectSet }
  let(:authorized_user) { owner }

  before(:each) do
    default_request scopes: scopes, user_id: owner.id
  end

  describe '#index' do
    let(:filterable_resources) { subject_sets }
    let(:expected_filtered_ids) { [ filterable_resources.first.id.to_s ] }
    let(:private_project) { create(:project, private: true) }
    let!(:private_resource) { create(:subject_set, project: private_project)  }
    let(:n_visible) { 2 }

    it_behaves_like 'is indexable'
    it_behaves_like 'has many filterable', :workflows

    it "is filterable by metadata" do
      subject_set = create(:subject_set, metadata: { artist: "Edvard Munch"})
      get :index, "metadata.artist" => "Edvard Munch"
      expect(json_response["subject_sets"][0]["id"]).to eq(subject_set.id.to_s)
    end

    describe 'sorting multiple subject sets' do
      let(:named_subject_sets) do
        [
          create(:subject_set, display_name: "Ze best set"),
          create(:subject_set, display_name: "An awesome set")
        ]
      end
      let(:set_display_names) do
        json_response["subject_sets"].map { |h| h["display_name"] }
      end

      before do
        named_subject_sets
      end

      it "is not sorted by default" do
        get :index, sort: "display_name"
        names = named_subject_sets.map(&:display_name)
        expect([set_display_names.first]).to_not include(names)
      end

      it "is sortable by display name", :aggregate_failures do
        get :index, sort: "display_name"
        expect(set_display_names.first).to eq("An awesome set")
        expect(set_display_names.last).to eq("Ze best set")
      end
    end
  end

  describe '#show' do
    let(:resource) { subject_set }

    it_behaves_like 'is showable'
  end

  describe '#update' do
    let(:subjects) { create_list(:subject, 4, project: project) }
    let(:workflow) { create(:workflow, project: project) }
    let(:resource) { create(:subject_set, project: project) }
    let(:resource_id) { :subject_set_id }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "A Better Name" }
    let(:test_relation) { :subjects }
    let(:test_relation_ids) { subjects.map { |s| s.id.to_s } }
    let(:update_params) do
      {
       subject_sets: {
                      display_name: "A Better Name",
                      expert_set: true,
                      links: {
                              workflows: [workflow.id.to_s],
                              subjects: subjects.map(&:id).map(&:to_s)
                             }

                     }
      }
    end

    it_behaves_like "is updatable"

    it_behaves_like "has updatable links"

    it_behaves_like "supports update_links"

    describe "update_links" do
      let(:sms_count) { resource.reload.set_member_subjects_count }
      let(:run_update_links) do
        default_request scopes: scopes, user_id: authorized_user.id
        params = {
          link_relation: test_relation.to_s,
          test_relation => test_relation_ids,
          resource_id => resource.id
        }
        post :update_links, params
      end

      it "should queue the counter worker" do
        expect(SubjectSetSubjectCounterWorker).to receive(:perform_in)
          .with(3.minutes, resource.id)
        run_update_links
      end

      context "when the linking resources are not persisted" do

        it "should return a 422 with a missing subject" do
          allow(subjects.last).to receive(:id).and_return(0)
          run_update_links
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "with illegal link properties" do
      it 'should return 422' do
        default_request user_id: authorized_user.id, scopes: scopes
        update_params[:subject_sets][:links].merge!(workflow: '1')
        update_params.merge!(id: resource.id)
        put :update, update_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "reload subject queue" do
      let(:workflows) { [create(:workflow, project: project)] }
      let(:resource) do
        create(:subject_set,project: project,subjects: subjects) do |sset|
          sset.workflows = workflows
        end
      end

      context "when the subject set has a workflow" do
        let(:workflow_id) { workflows.first.id }
        after do
          default_request scopes: scopes, user_id: authorized_user.id
          update_params[:subject_sets][:links].delete(:workflows)
          put :update, update_params.merge(id: resource.id)
        end

        it 'should call the reload queue worker' do
          expect(ReloadNonLoggedInQueueWorker).to receive(:perform_async)
          .with(workflow_id, resource.id)
        end

        it 'should not call the reload cellect worker when cellect is off' do
          expect(ReloadCellectWorker).not_to receive(:perform_async)
        end

        context "when cellect is on" do
          before do
            allow(Panoptes).to receive(:cellect_on).and_return(true)
          end

          it 'should not call reload cellect worker' do
            expect(ReloadCellectWorker).not_to receive(:perform_async)
          end

          it 'should call reload cellect worker when workflow uses cellect' do
            allow_any_instance_of(Workflow)
              .to receive(:using_cellect?).and_return(true)
            expect(ReloadCellectWorker)
              .to receive(:perform_async).with(workflow_id)
          end
        end
      end

      context "when the subject set has multiple workflows" do
        let(:workflows) { create_list(:workflow, 2, project: project) }
        after do
          default_request scopes: scopes, user_id: authorized_user.id
          update_params[:subject_sets][:links].delete(:workflows)
          put :update, update_params.merge(id: resource.id)
        end

        it 'should call the reload queue worker for each workflow' do
          workflows.each do |_workflow|
            expect(ReloadNonLoggedInQueueWorker).to receive(:perform_async)
            .with(_workflow.id, resource.id)
          end
        end

        it 'should not call the reload cellect worker when cellect is off' do
          expect(ReloadCellectWorker).not_to receive(:perform_async)
        end

        context "when cellect is on" do
          before do
            allow(Panoptes).to receive(:cellect_on).and_return(true)
          end

          it 'should not call reload cellect worker' do
            expect(ReloadCellectWorker).not_to receive(:perform_async)
          end

          it 'should call reload cellect worker when workflow uses cellect' do
            allow_any_instance_of(Workflow)
              .to receive(:using_cellect?).and_return(true)
            workflows.each do |_workflow|
              expect(ReloadCellectWorker).to receive(:perform_async)
              .with(_workflow.id)
            end
          end
        end
      end

      context "when the subject set has no workflows" do
        let(:workflows) { [] }
        after do
          default_request scopes: scopes, user_id: authorized_user.id
          update_params[:subject_sets][:links].delete(:workflows)
          put :update, update_params.merge(id: resource.id)
        end

        it 'should not call the reload queue worker' do
          expect(ReloadNonLoggedInQueueWorker).to_not receive(:perform_async)
        end

        it 'should not attempt to call cellect', :aggregate_failures do
          expect(Panoptes).not_to receive(:use_cellect?)
          expect(ReloadCellectWorker).not_to receive(:perform_async)
        end
      end

      context "when the subject set has no subjects" do
        let(:subjects) { [] }
        after do
          default_request scopes: scopes, user_id: authorized_user.id
          update_params[:subject_sets].delete(:links)
          put :update, update_params.merge(id: resource.id)
        end

        it 'should not call the reload queue worker' do
          expect(ReloadNonLoggedInQueueWorker).to_not receive(:perform_async)
        end

        it 'should not attempt to call cellect', :aggregate_failures do
          expect(Panoptes).not_to receive(:use_cellect?)
          expect(ReloadCellectWorker).not_to receive(:perform_async)
        end
      end
    end
  end

  describe '#create' do
    let(:test_attr) { :display_name}
    let(:test_attr_value) { 'Test subject set' }
    let(:create_params) do
      {
       subject_sets: {
                      display_name: 'Test subject set',
                      expert_set: true,
                      metadata: {
                                 location: "Africa"
                                },
                      links: {
                              project: project.id
                             }
                     }
      }
    end

    context "with illegal link properties" do
      it 'should return 422' do
        default_request user_id: authorized_user.id, scopes: scopes
        create_params[:subject_sets][:links].merge!(workflow: '1')
        post :create, create_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "create a new subject set" do
      it_behaves_like "is creatable"
    end

    context "create a subject set from a collection" do
      before(:each) do
        ps = create_params
        ps[:subject_sets][:links][:collection] = collection.id.to_s
        default_request user_id: authorized_user.id, scopes: scopes
        post :create, ps
      end

      context "when a user can access the collection" do
        let(:collection) { create(:collection_with_subjects) }
        it "should create a new subject set with the collection's subjects" do
          set = SubjectSet.find(created_instance_id(api_resource_name))
          expect(set.subjects).to match_array(collection.subjects)
        end
      end

      context "when the user cannot access the collection" do
        let(:collection) { create(:collection_with_subjects, private: true) }
        it "should return 404" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#destroy' do
    let(:resource) { subject_set }
    let(:sms) { resource.set_member_subjects }
    let(:delete_resources) do
      delete :destroy, id: subject_set.id
    end
    let(:linked_sms_ids) { sms.map(&:id) }
    let(:linked_subject_sets_workflows_ids) do
      resource.subject_sets_workflows.map(&:id)
    end

    it_behaves_like "is destructable"
    it_behaves_like "cleans up the linked set member subjects"

    it "should remove the linked subject_sets_workflow" do
      aggregate_failures "subject_sets_workflows" do
        expect(linked_subject_sets_workflows_ids.count).to be > 0
        delete_resources
        result = SubjectSetsWorkflow.where(id: linked_subject_sets_workflows_ids)
        expect(result).to be_empty
      end
    end
  end

  describe '#destroy_links' do
    context "removing subjects" do
      let(:sms) { subject_set.set_member_subjects }
      let(:linked_sms_ids) { sms.map(&:id) }

      let(:delete_resources) do
        delete :destroy_links,
          subject_set_id: subject_set.id,
          link_relation: :subjects,
          link_ids: subject_set.subjects.pluck(:id).join(',')
      end

      it_behaves_like "cleans up the linked set member subjects"
    end
  end
end
