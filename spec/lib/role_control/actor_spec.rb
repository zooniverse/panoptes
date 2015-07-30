require 'spec_helper'

RSpec.describe RoleControl::Actor do
  class HasActor
    include RoleControl::Actor
  end

  class ControlledResource < ActiveRecord::Base
    def self.scope(name=:name, lamda=nil); end
    def self.scope_for(action, user, opts={}); none end

    include RoleControl::Controlled
  end

  let(:with_actor) { HasActor.new }
  let(:action) { :index }

  describe "#do" do

    it "should return a DoChain object" do
      expect(with_actor.do(action)).to be_kind_of(RoleControl::Actor::DoChain)
    end
  end

  describe "DoChain Object" do

    let(:do_chain) { with_actor.do(action) }
    let(:controlled_resource) { ControlledResource.new }

    describe "#to" do

      it "should call scope_for" do
        expect(ControlledResource).to receive(:scope_for).with(action, with_actor, {})
        do_chain.to(ControlledResource)
      end

      it "should not call active" do
        allow(ControlledResource).to receive(:respond_to?).and_return(false)
        expect(ControlledResource).to_not receive(:active)
        do_chain.to(ControlledResource)
      end

      context "when passing add_active_scope: false" do

        it "should not call active" do
          allow(ControlledResource).to receive(:respond_to?).and_return(true)
          expect(ControlledResource).to_not receive(:active)
          do_chain.to(ControlledResource, add_active_scope: false)
        end
      end

      context "when the klass responds to active" do

        it "should not call active" do
          allow(ControlledResource).to receive(:respond_to?).and_return(true)
          expect(ControlledResource).to receive(:active).with(no_args)
          do_chain.to(ControlledResource)
        end
      end
    end

    describe "#with_ids" do
      let(:ids) { [1] }
      let(:do_chain_to) { do_chain.to(ControlledResource) }
      let(:scope) { do_chain_to.scope }

      before(:each) do
        allow(scope).to receive(:where).and_return(scope)
      end

      it "should call where on the scope" do
        expect(scope).to receive(:where).with(id: ids)
        do_chain_to.with_ids(ids)
      end

      it "should call order on the scope" do
        expect(scope).to receive(:order).with(:id)
        do_chain_to.with_ids(ids)
      end

      context "when ids are blank" do
        let(:ids) { [] }

        it "should not call where on the scope" do
          expect(scope).to_not receive(:where)
          do_chain_to.with_ids(ids)
        end

        it "should not call order on the scope" do
          expect(scope).to_not receive(:order)
          do_chain_to.with_ids(ids)
        end
      end
    end
  end
end
