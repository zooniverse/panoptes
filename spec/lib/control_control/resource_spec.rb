require 'spec_helper'

describe ControlControl::Resource do
  let(:fake_class) { Class.new { extend(ControlControl::Resource) } }

  describe "::can" do
    it 'should define a instance method is one has not been defined' do
      fake_class.can(:edit, :fake_method)
      expect(fake_class.new).to respond_to(:can_edit?)
    end

    it 'should accept a symbol as a filter' do
      fake_class.can(:edit, :fake_method)
      expect(fake_class.instance_variable_get(:@can_filters)[:edit]).to include(:fake_method)
    end

    it 'should accept a block instead of a filter' do
      fake_class.can(:edit) { |actor| actor.nil? }
      expect(fake_class.instance_variable_get(:@can_filters)[:edit][0]).to be_a(Proc)
    end

    it 'should create function that returns true when its filter is passed' do
      fake_class.__send__(:define_method, :fake_method, proc { |actor| actor.real? })
      fake_class.can(:edit, :fake_method)
      actor = double({ real?: true })
      expect(fake_class.new.can_edit?(actor)).to be_truthy
    end

    it 'should have to pass any filters to be true' do
      fake_class.can(:edit) { |actor| actor.real? }
      fake_class.can(:edit) { |actor| actor.chill? }
      actor1 = double({ real?: true, chill?: true })
      actor2 = double({ real?: true, chill?: false })
      actor3 = double({ real?: false, chill?: false })
      expect(fake_class.new.can_edit?(actor1)).to be_truthy
      expect(fake_class.new.can_edit?(actor2)).to be_truthy
      expect(fake_class.new.can_edit?(actor3)).to be_falsy
    end
  end
end
