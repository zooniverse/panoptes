require 'spec_helper'

RSpec.describe RoleControl::Actor do
  class HasActor
    include RoleControl::Actor
  end

  let(:actor) { HasActor.new }
  let(:action) { :index }

  let(:scope) do
    double.tap do |scope|
      allow(scope).to receive(:where).and_return(scope)
      allow(scope).to receive(:order).and_return(scope)
      allow(scope).to receive(:merge).and_return(scope)
    end
  end

  let(:klass) do
    double.tap do |klass|
      allow(klass).to receive(:scope_for).with(action, actor, {}).and_return(scope)
    end
  end

  describe "#scope" do
    it "should call scope_for" do
      expect(klass).to receive(:scope_for).with(action, actor, {})
      actor.scope(klass: klass, action: action)
    end

    context 'active scoping' do
      it "should call active if the klass responds to active" do
        allow(klass).to receive(:respond_to?).and_return(true)
        expect(klass).to receive(:active).with(no_args)
        actor.scope(klass: klass, action: action)
      end

      it "should not call active if the klass doesnt have an active scope" do
        allow(klass).to receive(:respond_to?).and_return(false)
        expect(klass).to_not receive(:active)
        actor.scope(klass: klass, action: action)
      end

      it "should not call active if passing add_active_scope: false" do
        allow(klass).to receive(:respond_to?).and_return(true)
        expect(klass).to_not receive(:active)
        actor.scope(klass: klass, action: action, add_active_scope: false)
      end
    end

    context "filtering to ids" do
      let(:ids) { [1] }

      before(:each) do
        allow(klass).to receive(:scope_for).and_return(scope)
        allow(scope).to receive(:where).and_return(scope)
      end

      it "should call where on the scope" do
        expect(scope).to receive(:where).with(id: ids)
        actor.scope(klass: klass, action: action, ids: ids)
      end

      it "should call order on the scope" do
        expect(scope).to receive(:order).with(:id)
        actor.scope(klass: klass, action: action, ids: ids)
      end

      context "when ids are blank" do
        let(:ids) { [] }

        it "should not call where on the scope" do
          expect(scope).to_not receive(:where)
          actor.scope(klass: klass, action: action, ids: ids)
        end

        it "should not call order on the scope" do
          expect(scope).to_not receive(:order)
          actor.scope(klass: klass, action: action, ids: ids)
        end
      end
    end
  end
end
