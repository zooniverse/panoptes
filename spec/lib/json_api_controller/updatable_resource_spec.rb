require 'spec_helper'

describe JsonApiController::UpdatableResource, type: :controller do
  class JsonApiController::BadLinkParams < StandardError; end
  controller(ApplicationController) do
    include JsonApiController::UpdatableResource

    def updated_resource_response
      render nothing: true
    end

    def deleted_resource_response
      render nothing: true
    end

    def resource_class
      Collection
    end

    def controlled_resources
      @controlled_resources ||= Collection.where(id: params[:id])
    end

    def serializer
      CollectionSerializer
    end
  end

  before(:each) do
    routes.draw do
      post "update_links" => "anonymous#update_links"
      delete "destroy_links" => "anonymous#destroy_links"
    end

    api_user = ApiUser.new(user)

    allow(controller).to receive(:api_user).and_return(api_user)
    allow(controller).to receive(:current_actor).and_return(api_user)
  end

  let(:user) { create(:user) }
  let(:resource) { create(:collection, owner: user) }
  let(:subjects) { create_list(:subject, 4) }

  describe "#update_links" do
    context "many-to-many" do
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
        end.to raise_error(JsonApiController::BadLinkParams)
      end
    end

    context "one-to-many and polymorphic" do
      it 'should add the new relation to the resource' do
        group = create(:user_group)
        create(:membership, state: :active, user: user, user_group: group, roles: ["group_admin"])
        post :update_links, {id: resource.id,
                             link_relation: :owner,
                             owner: {id: group.id,
                                     type: "user_group"}}
        resource.reload
        expect(resource.owner).to eq(group)
      end
    end

    context "belongs-to-many" do
      it 'should add the new relation to the resource' do
        project = create(:project)
        post :update_links, {id: resource.id,
                             link_relation: :projects,
                             projects: [project.id]}
        resource.reload
        expect(resource.projects).to include(project)
      end
    end
  end

  describe "#destroy_links" do
    context 'habtm' do
      before(:each) do
        resource.subjects = subjects
        resource.save!
      end

      it 'should remove included relations' do
        delete :destroy_links, {id: resource.id,
                                link_relation: :subjects,
                                link_ids: subjects[0..1].map(&:id).join(',')}
        resource.reload
        expect(resource.subjects).to include(*subjects[2..-1])
        expect(resource.subjects).to_not include(*subjects[0..1])
      end

      it 'should not destroy then items' do
        expect do
          delete :destroy_links, {id: resource.id,
                                  link_relation: :subjects,
                                  link_ids: subjects[0..1].map(&:id).join(',')}
        end.to_not change{ Subject.count }
      end
    end
  end
end
