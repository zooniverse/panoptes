require 'spec_helper'

describe Api::V1::CollectionsController, type: :controller do
  let(:owner) { create(:user) }
  let!(:collections) { create_list :collection_with_subjects, 2, owner: owner }
  let(:collection) { collections.first }
  let(:project) { collection.projects.sample }
  let(:api_resource_name) { 'collections' }

  let(:api_resource_attributes) { %w(id name display_name created_at updated_at favorite private description) }
  let(:api_resource_links) { %w(collections.projects collections.owner collections.collection_roles collections.subjects) }

  let(:scopes) { %w(public collection) }
  let(:authorized_user) { owner }
  let(:resource_class) { Collection }

  before(:each) do
    default_request scopes: scopes
  end

  describe '#index' do
    let(:filterable_resources) { collections }
    let(:expected_filtered_ids) { [ filterable_resources.first.id.to_s ] }
    let!(:private_resource) do
      create :collection_with_subjects, private: true
    end
    let(:resource) { collection }
    let(:n_visible) { 2 }
    let(:deactivated_resource) { create(:collection, activated_state: :inactive) }

    it_behaves_like "is indexable"
    it_behaves_like "it has custom owner links", "display_name"
    it_behaves_like "it only lists active resources"
    it_behaves_like "filter by display_name"
    it_behaves_like 'has many filterable', :subjects

    describe "filtering" do
      let(:owner_resources) { collections }
      let(:collab_collection) { create(:collection) }
      let(:collab_resource) { collab_collection }
      let(:viewer_resource) { private_resource }

      it_behaves_like "filters by owner"
      it_behaves_like "filters by current user roles"

      describe "project_ids" do
        let(:project_ids){ collections.map(&:project_ids).flatten }
        let(:expected_filtered_ids) { collections.map(&:id).map(&:to_s) }

        it_behaves_like 'belongs to many filterable', :projects do
          let(:filter_ids) { project_ids.join(",") }
        end

        context "single project_ids" do
          let(:project_ids){ collections.first.project_ids }
          let(:expected_filtered_ids) { [ collections.first.id.to_s ] }

          it_behaves_like 'belongs to many filterable', :projects do
            let(:filter_ids) { project_ids.join(",") }
          end
        end

        context "on singular resource" do
          let(:expected_filtered_ids) { [ collections.first.id.to_s ] }

          it_behaves_like 'has many filterable', :projects do
            let(:filter_ids) { collections.first.project_ids.first }
          end
        end
      end

      describe "by favorite" do
        let!(:favorite_col) { create(:collection, favorite: true) }

        it 'should only return the favorite collection' do
          get :index, favorite: true
          expect(json_response[api_resource_name].map{ |r| r['id'] }).to match_array([favorite_col.id.to_s])
        end
      end
    end
  end

  describe '#show' do
    let(:resource) { collection }

    it_behaves_like "is showable"
  end

  describe '#update' do
    let(:subjects) { create_list(:subject, 4) }
    let(:resource) { collection }
    let(:resource_id) { :collection_id }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "Tested Collection" }
    let(:test_relation) { :subjects }
    let(:test_relation_ids) { subjects.map(&:id) }
    let(:update_params) do
      {
       collections: {
                     display_name: "Tested Collection",
                     description: "Super tested collection of subjects, very good very nice",
                     private: false,
                     links: {
                             subjects: subjects.map(&:id).map(&:to_s)
                            }
                    }
      }
    end

    it_behaves_like "is updatable"
    it_behaves_like "has updatable links"
    it_behaves_like "supports update_links"

    context "when the subject is already in a collection" do
      let!(:test_relation_ids) { Array.wrap(collection.subjects.first.id) }
      let(:params) do
        {
          link_relation: test_relation.to_s,
          test_relation => test_relation_ids,
          resource_id => resource.id
        }
      end

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it "should return a useful error message" do
        post :update_links, params
        aggregate_failures "dup link ids" do
          expect(response).to have_http_status(:bad_request)
          error_body = "Validation failed: Subject is already in the collection"
          expect(response.body).to eq(json_error_message(error_body))
        end
      end

      it "should handle duplicate index violations gracefully" do
        msg = "ERROR: duplicate key value violates unique constraint"
        error = ActiveRecord::RecordNotUnique.new(msg, PG::UniqueViolation)
        allow(subject).to receive(:add_relation).and_raise(error)
        post :update_links, params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe '#create' do
    let(:test_attr) { :name }
    let(:test_attr_value) { 'test__collection' }
    let(:create_links) { { projects: [ project.id ] } }
    let(:create_params) do
      {
       collections: {
                     name: 'test__collection',
                     display_name: 'Fancy name',
                     private: false,
                     description: "Such a good collection, the best, amazing",
                     links: create_links
                    }
      }
    end

    it_behaves_like 'is creatable'

    context "with singular project link object" do
      let(:create_links) { { project: project.id } }

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end

      it "should return created", :aggregate_failures do
        expect(response).to have_http_status(:created)
        created_links = created_instance(api_resource_name)["links"]
        expect(created_links.has_key?("projects")).to be_truthy
      end

      context "when passing inconsistent project links" do
        let(:create_links) { { project: project.id, projects: [1,2] } }

        it "should return an error" do
          msg = "Error: project_ids and project link keys must not be set together"
          expect(response.body).to eq(json_error_message(msg))
        end
      end
    end
  end

  describe '#destroy' do
    let(:resource) { collection }

    it_behaves_like "is destructable"
  end

  describe '#destroy_links' do
    context "removing the default subject from the collection" do
      let(:default_subject) { collection.subjects.first }

      def delete_default(ids)
        delete :destroy_links,
          collection_id: collection.id,
          link_relation: :subjects,
          link_ids: ids
      end

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        collection.update({default_subject: default_subject})
      end

      context "nulls the default subject relation" do
        it "when there is a single subject given" do
          delete_default(default_subject.id.to_s)
          expect(collection.reload.default_subject).to be_nil
        end

        it "when there is an array of subjects given" do
          delete_default(collection.subjects.pluck(:id).join(','))
          expect(collection.reload.default_subject).to be_nil
        end
      end
    end
  end
end
