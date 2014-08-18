require 'spec_helper'

class Admined
  extend ControlControl::Resource
  include RoleControl::Adminable
end

class Admin
  def initialize(admin=true)
    @admin = admin
  end

  def is_admin?
    @admin
  end
end

describe RoleControl::Adminable do
  let(:obj) { Admined.new }
  
  it 'should have defined can_*? methods' do
    expect(obj).to respond_to(:can_show?)
    expect(obj).to respond_to(:can_update?)
    expect(obj).to respond_to(:can_destroy?)
  end

  describe "#admin?" do
    it "should test actor's is_admin? method" do
      admin = Admin.new
      expect(admin).to receive(:is_admin?)
      obj.admin?(admin)
    end

    it 'should return true when admin.is_admin? is true' do
      admin = Admin.new
      expect(obj.admin?(admin)).to be_truthy
    end

    it 'should return false when admin.is_admin? is false' do
      admin = Admin.new(false)
      expect(obj.admin?(admin)).to be_falsy
    end
  end
end
