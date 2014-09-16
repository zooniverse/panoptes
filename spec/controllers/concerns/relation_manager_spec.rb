require 'spec_helper'

describe RelationManager do
  class Api::BadLinkParams < StandardError; end
  
  let!(:resource) { create(:collection_with_subjects) }

  let(:test_class) do
    Class.new do
      include RelationManager

      def initialize(resource)
        @resource, @klass = resource, resource.class
      end

      def controlled_resource
        @resource
      end

      def resource_class
        @klass
      end
    end
  end

  let(:test_instance) { test_class.new(resource) }

  let(:user) { create(:user) }
  let(:subjects) { create_list(:subject, 4, owner: user) }

  describe "#update_relations" do
    it 'should error when passed a nil value' do
      expect do
        test_instance.update_relation(:subjects, nil)
      end.to raise_error(Api::BadLinkParams)
    end
    
    context "many-to-many" do
      context "add" do
        it 'should add the new relation to the resource' do
          test_instance.update_relation(:subjects,
                                        subjects.map(&:id).map(&:to_s))
          expect(resource.subjects).to include(*subjects)
        end
      end

      context "replace" do
        it 'should replace the relation with new items' do
          test_instance.update_relation(:subjects,
                                        subjects.map(&:id).map(&:to_s),
                                        true)
          expect(resource.subjects).to eq(subjects)
        end
      end
    end

    context "one-to-many" do
      it 'should add the new relation to the resource' do
        project = create(:project)
        test_instance.update_relation(:project, project.id)
        expect(resource.project).to eq(project)
      end
    end

    context "polymorphic" do
      it 'should add the new relation to the resource' do
        group = create(:user_group)
        test_instance.update_relation(:owner, {id: group.id.to_s,
                                               type: "user_group"})
        expect(resource.owner).to eq(group)
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
