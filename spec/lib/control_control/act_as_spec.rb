require 'spec_helper'

class TestActAs
  extend ControlControl::Resource
  extend ControlControl::ActAs

  can_as :update, :update_test

  def update_test(actor, target)
    actor.allowed
  end
end

class TestActor
  include ControlControl::Actor

  attr_reader :allowed
  
  def initialize(allowed=true) 
    @allowed = allowed
  end
end

describe ControlControl::ActAs do
  let(:target) { double({ can_update?: true }) }
  let(:act_as) { TestActAs.new }
  let(:allowed_actor) { TestActor.new }
  let(:not_allowed_actor) { TestActor.new(false) }
  
  it 'should allow an allowed actor to act as it' do
    result = allowed_actor.do(:update).to(target).as(act_as).allowed?
    expect(result).to be_truthy
  end

  it 'should throw an error when a not allowed actor tries to act as it' do
    expect do
      not_allowed_actor.do(:update)
        .to(target)
        .as(act_as)
        .allowed?
    end.to raise_error(ControlControl::AccessDenied)
  end
end
