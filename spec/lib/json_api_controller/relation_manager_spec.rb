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

      def controlled_resource
        @resource
      end

      def current_actor
        @user
      end

      def resource_class
        @klass
      end
    end
  end


  let(:user) { create(:user) }
  let(:subjects) { create_list(:subject, 4, owner: user) }
  let(:project) { create(:project) }
  
  let(:test_instance) { test_class.new(resource, user) }

  describe "#update_relations" do
    context "many-to-many" do
      it 'should replace the relation with new items' do
        test_instance.update_relation(:subjects,
                                      subjects.map(&:id).map(&:to_s))
        expect(resource.subjects).to eq(subjects)
      end
    end

    context "one-to-many" do
      it 'should add the new relation to the resource' do
        test_instance.update_relation(:project, project.id)
        expect(resource.project).to eq(project)
      end
    end

    context "polymorphic" do
      it 'should add the new relation to the resource' do
        group = create(:user_group)
        create(:membership, user: user, user_group: group, state: :active, roles: ["group_admin"])
        test_instance.update_relation(:owner, {id: group.id.to_s,
                                               type: "user_group"})
        expect(resource.owner).to eq(group)
      end
    end
  end

  describe "#add_relation" do
    context "to-many" do
      it 'should add the new relation to the resource' do
        test_instance.add_relation(:subjects,
                                   subjects.map(&:id).map(&:to_s))
        expect(resource.subjects).to include(*subjects)
      end
    end
    
    context "to-one" do
      it 'should replace the old relation' do
        test_instance.add_relation(:project, project.id)
        expect(resource.project).to eq(project)
      end
    end
  end


  describe "#destroy_relation" do
    it 'should remove the linked relations' do
      del_string = resource.subjects[0..2].map(&:id).join(",")
      test_instance.destroy_relation(:subjects, del_string)
      expect(resource.subjects).to_not include(*subjects[0..2])
    end
    
    context "habtm" do
      it 'should not destroy the unlinked items' do
        expect do
          del_string = resource.subjects[0..2].map(&:id).join(",")
          test_instance.destroy_relation(:subjects, del_string)
        end.to_not change{ Subject.count }
      end
    end

    context "has_many" do
      let!(:resource) { create(:project_with_workflows) }
      
      it 'should destroy the unlinked items' do
        expect do
          del_string = resource.workflows.map(&:id).join(",")
          test_instance.destroy_relation(:workflows, del_string)
        end.to change{ Workflow.count }.from(2).to(0)
      end
    end
  end
end
