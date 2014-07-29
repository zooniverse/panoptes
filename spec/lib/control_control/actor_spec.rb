require 'spec_helper'

describe ControlControl::Actor do
  let(:fake_actor) { Class.new{ include ControlControl::Actor }.new }
  let(:fake_resource) { double({ can_update?: true }) }
  let(:bad_resource) { double({ can_update?: false }) }
  let(:on_behalf_resource) { double({ can_act_on_as?: true, do_to_resource: true }) }
  let(:bad_on_behalf_resource) { double({ can_act_on_as?: false, do_to_resource: true }) }

  describe "#do_to_resource_on_behalf_of" do
    it 'should raise error if not allowed to act' do
      expect do
        fake_actor.do_to_resource_on_behalf_of(bad_on_behalf_resource,
                                               :update,
                                               fake_resource) { |r| update!(r) }
      end.to raise_error(ControlControl::AccessDenied)
    end

    it 'should not raise error when allowed to act' do
      expect do
        fake_actor.do_to_resource_on_behalf_of(on_behalf_resource,
                                               :update,
                                               fake_resource) { |r| update!(r) }
      end.to_not raise_error
    end

    it 'should call do_to_resource on the acting resource' do
      expect(on_behalf_resource).to receive(:do_to_resource).with(fake_resource,
                                                                  :update)
      fake_actor.do_to_resource_on_behalf_of(on_behalf_resource,
                                             :update,
                                             fake_resource) { |r| update!(r) }
    end
  end

  describe "#do_to_resource" do
    def action(resource)
      fake_actor.do_to_resource(resource, :update) do |owner|
        update!(owner)
      end
    end
    
    it 'should raise an error when the actor is not allowed to act' do
      expect{ action(bad_resource) }.to raise_error(ControlControl::AccessDenied)
    end

    it 'should not call the supplied block if not allowed to act' do
      expect(bad_resource).to_not receive(:update!)
      action(bad_resource) rescue nil
    end

    it 'should not raise an error when allowed to act' do
      allow(fake_resource).to receive(:update!).with(fake_actor)
      expect{ action(fake_resource) }.to_not raise_error
    end

    it 'should call the passed block when allows' do
      expect(fake_resource).to receive(:update!).with(fake_actor)
      action(fake_resource)
    end
  end
end
