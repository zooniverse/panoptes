require 'spec_helper'

describe JsonApiController::RelationManager do
  let!(:resource) { create(:collection_with_subjects) }

  let(:test_class) do
    Class.new do
      include JsonApiController::RelationManager

      def initialize(resource, user)
        @resource, @klass = resource, resource.class
        @user = ApiUser.new(user)
      end

      def api_user
        @user
      end

      def resource_class
        @klass
      end
    end
  end


  let(:user) { create(:user) }
  let(:project) { create(:project, owner: user) }
  let(:subjects) { create_list(:subject, 2, project: project) }
  let(:owner_group) { create(:user_group) }
  let(:owner_role) do
    create(:membership, user: user, user_group: owner_group, state: :active, roles: ["group_admin"])
  end

  let(:test_instance) { test_class.new(resource, user) }

  describe "#update_relations" do
    context "many-to-many" do
      it 'should replace the relation with new items' do
        updated = test_instance.update_relation(resource,
                                                :subjects,
                                                subjects.map(&:id).map(&:to_s))
        expect(updated).to match_array(subjects)
      end

      context 'empty link' do
        it 'should set to empty collection' do
          updated = test_instance.update_relation(resource, :subjects, [])
          expect(updated).to be_empty
        end
      end

      context "not found" do
        it 'should raise an error' do
          expect do
            test_instance.update_relation(resource, :subjects, [-10, -2])
          end.to raise_error(JsonApiController::NotLinkable, /subjects\s/)
        end
      end

    end

    context "one-to-many and polymorphic" do
      let(:owner_id) { owner_group.id.to_s }
      let(:update_params) do
        [ resource, :owner, {id: owner_id, type: "user_group"} ]
      end

      before(:each) { owner_role }

      it 'should add the new relation to the resource' do
        updated = test_instance.update_relation(*update_params)
        expect(updated).to eq(owner_group)
      end

      context "not found" do
        let(:owner_id) { -10.to_s }
        it 'should raise an error' do
          expect do
            test_instance.update_relation(*update_params)
          end.to raise_error(JsonApiController::NotLinkable, /user_group\s/)
        end
      end
    end

    context "belongs-to-many" do
      it 'should add the new relation to the resource' do
        updated = test_instance.update_relation(resource, :projects, [project.id])
        expect(updated).to match_array([project])
      end

      context 'empty link' do
        it 'should set to empty collection' do
          updated = test_instance.update_relation(resource, :projects, [])
          expect(updated).to be_empty
        end
      end
    end
  end

  describe "#add_relation" do
    context "to-many" do
      it 'should add the new relation to the resource' do
        test_instance.add_relation(resource, :subjects, subjects.map(&:id).map(&:to_s))
        expect(resource.subjects).to include(*subjects)
      end

      it 'should allow adding no items' do
        test_instance.add_relation(resource, :subjects, subjects.map(&:id).map(&:to_s))
        test_instance.add_relation(resource, :subjects, [])
        expect(resource.subjects).to include(*subjects)
      end
    end

    context "to-one" do
      it 'should replace the old relation' do
        owner_role
        params = {id: owner_group.id.to_s, type: "user_group"}
        test_instance.add_relation(resource, :owner, params)
        expect(resource.owner).to eq(owner_group)
      end
    end

    context "belongs-to-many" do
      it 'should replace the old relation' do
        test_instance.add_relation(resource, :projects, [project.id])
        expect(resource.projects).to include(*project)
      end

      it 'should allow adding no items' do
        test_instance.add_relation(resource, :projects, [project.id])
        test_instance.add_relation(resource, :projects, [])
        expect(resource.projects).to include(*project)
      end
    end
  end

  describe "#destroy_relation" do
    def destroy_helper
      test_instance.destroy_relation(resource, relation, del_string)
    end

    context "has_many through" do
      let(:resource_to_remove) { resource.subjects[0..2] }
      let(:relation) { :subjects }
      let(:del_string) { resource_to_remove.map(&:id).join(",") }

      it "does not destroy the unlinked items" do
        expect{ destroy_helper }.to_not change{Subject.count}
      end

      it "removes the linked relations" do
        destroy_helper
        expect(resource.subjects).to_not include(*resource_to_remove)
      end

      it "deletes the join table record" do
        expect{ destroy_helper }.to change{ CollectionsSubject.count }.by(-2)
      end
    end

    context "has_many" do
      let(:resource) { create(:project_with_workflows) }
      let(:resource_to_remove) { resource.workflows[0..2] }
      let(:relation) { :workflows }
      let(:del_string) { resource.workflows.map(&:id).join(",") }

      it "does not destroy the unlinked items" do
        expect{ destroy_helper }.to change{ Workflow.count }.by(0)
      end

      it "removes the linked relation" do
        destroy_helper
        expect(resource.workflows).to_not include(*resource_to_remove)
      end
    end

    context "has_and_belongs_to_many" do
      let(:resource) { create(:classification) }
      let(:resource_to_remove) { resource.subjects[0] }
      let(:resource_to_remain) { resource.subjects[1] }
      let(:relation) { :subjects }
      let(:del_string) { resource_to_remove.id.to_s }

      it "does not destroy the unlinked items" do
        expect{ destroy_helper }.to_not change{Subject.count}
      end

      it "removes the linked relation" do
        destroy_helper
        expect(resource.subjects).to_not include(*resource_to_remove)
      end

      it "removes ONLY the specified linked relation" do
        destroy_helper
        expect(resource.subjects).to include(*resource_to_remain)
      end
    end

    context "belongs_to" do
      let(:resource) { create(:organization, projects: [project]) }
      let(:resource_to_remove) { resource.projects[0] }
      let(:relation) { :projects }
      let(:del_string) { resource.projects.map(&:id).join(",") }

      it "does not destroy the unlinked item" do
        expect{ destroy_helper }.to change{ Project.count }.by(0)
      end

      it "removes the linked relation" do
        destroy_helper
        expect(resource.projects).to_not include(*resource_to_remove)
      end
    end
  end
end
