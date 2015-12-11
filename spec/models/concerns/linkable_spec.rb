require 'spec_helper'

describe Linkable do
  let(:test_class) do
    Class.new do
      include Linkable

      def scope_for(action, actor)
        return [action, actor]
      end
    end
  end

  let(:link_scopes) { test_class.instance_variable_get(:@link_scopes) }
  let(:actor) { ApiUser.new(create(:user)) }
  let(:model) { create(:project) }
  let(:alt_model) { create(:collection) }

  describe "link_scopes" do
    it 'should default to default_link_to_resource_scope with the actor as an arguement' do
      expect(link_scopes[:literally_anything]).to eq([:default_link_to_scope, :user])
    end

  end

  describe "::can_be_linked" do
    it 'should add a scope to link_scopes' do
      test_class.instance_eval do
        can_be_linked :projects, :scope_for, :destroy, :user
      end

      expect(link_scopes[Project]).to eq([:scope_for, :destroy, :user])
    end
  end

  describe "::link_to_resource" do
    context "no defined link" do
      it 'call default_link_to_resource_scope with the actor' do
        expect(test_class).to receive(:default_link_to_scope).with(actor)
        test_class.link_to_resource(model, actor)
      end
    end

    context "a defined link_scope" do
      before(:each) do
        test_class.instance_eval do
          can_be_linked :project, :fake_method, :user, :model, 10
          can_be_linked :collection, :fake_method, :update, :user

          def self.fake_method(actor, model, int)
            [actor, model, int]
          end
        end
      end

      it 'should substitute user for the :user arg' do
        expect(test_class.link_to_resource(model, actor)[0]).to eq(actor)
      end

      it 'should substitute :model for the model arg' do
        expect(test_class.link_to_resource(model, actor)[1]).to eq(model)
      end

      it 'should call the given method' do
        expect(test_class).to receive(:fake_method).with(actor, model, 10)
        test_class.link_to_resource(model, actor)
      end
    end
  end
end
