require 'spec_helper'

describe RoleControl::Controlled do
  setup_role_control_tables
  
  let(:subject) { ControlledTable }
  
  let(:controlled) do
    s = subject.new
    s.visible_to = [ "test_role" ]
    s.save!
    s
  end
  
  let(:enrolled) do
    e = EnrolledTable.new
    e.save!
    e
  end
  
  let(:unenrolled) do
    u = EnrolledTable.new
    u.save!
    u
  end

  describe "::can_create?" do
    it 'should return true when passed a non-nil value' do
      expect(subject.can_create?(Object.new)).to be_truthy
    end

    it 'should return false when passed a nil value' do
      expect(subject.can_create?(nil)).to be_falsy
    end
  end

  describe "::scope_for" do
    let!(:group_tables) do
      gt1 = subject.new
      gt2 = subject.new
      gt3 = subject.new

      gt1.visible_to = []
      gt2.visible_to = %w(admin test_role)
      gt3.visible_to = %w(admin)
      [gt1,gt2,gt3].each(&:save!)

      m1 = RoleModelTable.new
      m1.roles = ['admin']
      m1.controlled_table = gt1
      m1.enrolled_table = enrolled
      
      m2 = RoleModelTable.new
      m2.roles = ['test_role']
      m2.controlled_table = gt2
      m2.enrolled_table = enrolled
      
      m3 = RoleModelTable.new
      m3.roles = ['test_role']
      m3.controlled_table = gt3
      m3.enrolled_table = enrolled
      
      m4 = RoleModelTable.new
      m4.roles = []
      m4.controlled_table = gt3
      m4.enrolled_table = unenrolled
      [m1,m2,m3,m4].each(&:save!)
      [gt1, gt2, gt3]
    end

    it 'should return an active record relation' do
      expect(subject.scope_for(:read, enrolled)).to be_an(ActiveRecord::Relation)
    end

    it 'should fetch all records that are visible to an actor' do
      expect(subject.scope_for(:read, enrolled).length).to eq(2)
    end

    it 'should not fetch records invisible to an actor' do
      expect(subject.scope_for(:read, unenrolled).length).to_not eq(3)
      expect(subject.scope_for(:read, unenrolled).length).to eq(1)
    end

    it 'should fetch all publicly visible records for unenrolled actor' do
      test_user = Class.new{ include RoleControl::UnrolledUser }.new
      expect(subject.scope_for(:read, test_user).length).to eq(1)
    end
  end

  describe "::can_by_role" do
    before(:each) do
      mt = RoleModelTable.new
      mt.enrolled_table = enrolled
      mt.controlled_table = controlled
      mt.roles = ["test_role"]
      mt.save!

      mt2 = RoleModelTable.new
      mt2.enrolled_table = unenrolled
      mt2.controlled_table = controlled
      mt2.roles = []
      mt2.save!
    end
    
    it 'should create an instance method to test the action' do 
      expect(controlled).to respond_to(:can_read?)
    end

    it 'should create a proc to test when roles are present' do
      subject.instance_eval { can_by_role :edit, roles: [:test_role] }
      expect(subject.instance_variable_get(:@can_filters)[:edit].first).to be_a(Proc)
    end

    it 'should return true when passed an enrolled object with roles' do
      expect(controlled.can_read?(enrolled)).to be_truthy
    end

    it 'should return false when passed an unenrolled object with no roles' do
      expect(controlled.can_read?(unenrolled)).to be_falsy
    end
  end
end
