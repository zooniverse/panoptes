require 'spec_helper'

describe RoleControl::Controlled do
  setup_role_control_tables
  
  let(:subject) { GroupTable }

  describe "::can_create?" do
    it 'should return true when passed a non-nil value' do
      expect(subject.can_create?(Object.new)).to be_truthy
    end

    it 'should return false when passed a nil value' do
      expect(subject.can_create?(nil)).to be_falsy
    end
  end

  describe "::can_by_role" do
    let(:controlled) { subject.new }
    let(:enrolled) { RoleModelTable.new }
    let(:unenrolled) { RoleModelTable.new }
    before(:each) do
      controlled.save!
      enrolled.save!
      unenrolled.save!
      
      mt = MembershipTable.new
      mt.role_model_table_id = enrolled.id
      mt.group_table_id = controlled.id
      mt.roles = ["test_role"]
      mt.save!

      mt2 = MembershipTable.new
      mt2role_model_table_id = unenrolled.id
      mt2group_table_id = controlled.id
      mt2.roles = []
      mt2.save!
    end
    
    it 'should create an instance method to test the action' do 
      expect(controlled).to respond_to(:can_read?)
    end

    it 'should create a proc to test when roles are present' do
      subject.instance_eval { can_by_role :edit, :test_role }
      expect(subject.instance_variable_get(:@can_filters)[:edit].first).to be_a(Proc)
    end

    it 'should return true when passed an enrolled object with roles' do
      expect(subject.new.can_read?(enrolled)).to be_truthy
    end

    it 'should return false when passed an unenrolled object with no roles' do
      expect(subject.new.can_read?(unenrolled)).to be_falsy
    end
  end
end
