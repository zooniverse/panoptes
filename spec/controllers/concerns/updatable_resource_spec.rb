require 'spec_helper'

describe UpdatableResource, type: :controller do
  class Api::BadLinkParams < StandardError; end
  
  controller(ApplicationController) do
    include UpdatableResource

    def update_response
      render nothing: true
    end

    def deleted_resource_response
      render nothing: true
    end

    def resource_class
      Collection
    end

    def controlled_resource
      Collection.find(params[:id])
    end

    def link_params
      { subjects: [], project: nil } end

    def serializer
      CollectionSerializer
    end
  end

  let(:resource) { create(:collection_with_subjects) }
  let(:user) { create(:user) }

  before(:each) do
    routes.draw do
      post "update_links" => "anonymous#update_links"
      delete "destroy_links" => "anonymous#destroy_links"
    end

    allow(controller).to receive(:api_user).and_return(ApiUser.new(user))
  end

  describe "#update_links" do
    context "to-many relation" do
      let(:subjects) { create_list(:subject, 4, owner: user) }
      
      it 'should add the new relations to the resource' do
        post :update_links, {id: resource.id,
                             link_relation: :subjects,
                             subjects: subjects.map(&:id).map(&:to_s)}
        expect(resource.subjects).to include(*subjects)
      end

      it 'should error when the relation does not match the link' do
        expect do
        post :update_links, {id: resource.id,
                             link_relation: :sujbcts,
                             subjects: subjects.map(&:id).map(&:to_s)}
        end.to raise_error(Api::BadLinkParams)
      end
    end

    context "to-one relation" do
      let(:project) { create(:project, owner: user) }
      it 'should replace the current relation with the new one' do
        post :update_links, {id: resource.id,
                             link_relation: :project,
                             project: project.id}
        resource.reload
        expect(resource.project).to eq(project)
      end
    end
  end

  describe "#destroy_links" do
    context "to-many relation" do
      it 'should remove included relations' do
        delete :destroy_links, {id: resource.id,
                                link_relation: :subjects,
                                link_ids: resource.subjects
                                  .map(&:id).join(',')}
        expect(resource.subjects).to be_empty
      end
    end

    context "to-one relation" do
      it 'should set the relation to nil' do
        delete :destroy_links, {id: resource.id,
                                link_relation: :project,
                                link_ids: resource.project.id}
        expect(resource.project).to be_nil
      end
    end
  end
end
