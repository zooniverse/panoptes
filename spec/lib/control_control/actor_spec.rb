require 'spec_helper'

describe ControlControl::Actor do
  let(:fake_actor) { Class.new{ include ControlControl::Actor }.new }
  let(:fake_resource) { double({ can_update?: true }) }
  let(:bad_resource) { double({ can_update?: false }) }
  let(:on_behalf_resource) { double({ can_update_as?: true, do: true }) }
  let(:bad_on_behalf_resource) { double({ can_update_as?: false, do: true }) }

  describe "#do" do
    context "when acting as another resource" do
      it 'should raise error if not allowed to act' do
        expect do
          fake_actor.do(:update)
            .to(fake_resource)
            .as(bad_on_behalf_resource)
            .call { |r| update!(r) }
        end.to raise_error(ControlControl::AccessDenied)
      end

      it 'should not raise error when allowed to act' do
        allow(fake_resource).to receive(:update!)
        expect do
          fake_actor.do(:update)
            .to(fake_resource)
            .as(on_behalf_resource)
            .call { |a,r| r.update!(a) }
        end.to_not raise_error
      end
    end

    context "when not acting as another resource" do
      def action(resource)
        fake_actor.do(:update).to(resource).call do |owner, resource|
          resource.update!(owner)
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

      it 'should call the passed block when allowed' do
        expect(fake_resource).to receive(:update!).with(fake_actor)
        action(fake_resource)
      end
    end
  end
end
