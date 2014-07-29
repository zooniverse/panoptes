require 'spec_helper'

describe ControlControl::Resource do
  let(:fake_class) { Class.new { include(ControlControl::Resource) } }
  let(:fake_object) { fake_class.new }
  let(:actor) { double({ owns?: true }) }
  let(:not_actor) { double({ owns?: false }) }

  describe "::can_create?" do
    it 'should return true by defaul' do
      expect(fake_class.can_create?(actor)).to be_truthy
    end
  end

  describe "::multi_read_scope" do
    it 'should return all' do
      expect(fake_class).to receive(:all)
      fake_class.multi_read_scope(actor)
    end
  end

  describe "#can_act?" do
    it 'should return true when actor is owner' do
      expect(fake_object.can_act?(actor)).to be_truthy
    end

    it 'should return fale when actor is not owner' do
      expect(fake_object.can_act?(not_actor)).to be_falsy
    end
  end

  describe "#is_resource_owner?" do
    it "should call the actor's owns? method" do
      expect(actor).to receive(:owns?)
      fake_object.is_resource_owner?(actor)
    end
  end
end
