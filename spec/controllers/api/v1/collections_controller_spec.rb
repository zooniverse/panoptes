require 'spec_helper'

describe Api::V1::CollectionsController, type: :controller do
  let(:owner) { create(:user) }
  let!(:collections) { create_list :collection_with_subjects, 2, owner: owner }
  let(:collection) { collections.first }
  let(:project) { collection.project }
  let(:api_resource_name) { 'collections' }

  let(:api_resource_attributes) { %w(id name display_name created_at updated_at favorite private) }
  let(:api_resource_links) { %w(collections.project collections.owner collections.collection_roles collections.subjects) }

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
    it_behaves_like "it has custom owner links"
    it_behaves_like 'has many filterable', :subjects
    it_behaves_like "it only lists active resources"

    context "it is filterable by favorite" do
      let!(:favorite_col) { create(:collection, favorite: true) }

      it 'should only return the favorite collection' do
        get :index, favorite: true
        expect(json_response[api_resource_name].map{ |r| r['id'] }).to match_array([favorite_col.id.to_s])
      end
    end

    it_behaves_like "filter by display_name"
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
    let(:create_params) do
      {
       collections: {
                     name: 'test__collection',
                     display_name: 'Fancy name',
                     private: false,
                     links: { project: project.id }
                    }
      }
    end

    it_behaves_like 'is creatable'
  end

  describe '#destroy' do
    let(:resource) { collection }

    it_behaves_like "is destructable"
  end
end
