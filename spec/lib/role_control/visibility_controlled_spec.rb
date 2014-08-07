require 'spec_helper'

describe RoleControl::VisibilityControlled do
  setup_role_control_tables

  let(:subject) do
    GroupTable.instance_eval do
      include RoleControl::VisibilityControlled
    end
    
  end

  let!(:enrolled) { rmt = RoleModelTable.new; rmt.save!; rmt }
  let!(:unenrolled) { rmt = RoleModelTable.new; rmt.save!; rmt }

  let!(:group_tables) do
    gt1 = subject.new
    gt2 = subject.new
    gt3 = subject.new

    gt1.visible_to = []
    gt2.visible_to = %w(admin test_role)
    gt3.visible_to = %w(admin)
    [gt1,gt2,gt3].each(&:save!)

    m1 = MembershipTable.new
    m1.roles = ['admin']
    m1.group_table_id = gt1.id
    m1.role_model_table_id = enrolled.id
    
    m2 = MembershipTable.new
    m2.roles = ['test_role']
    m2.group_table_id = gt2.id
    m2.role_model_table_id = enrolled.id
    
    m3 = MembershipTable.new
    m3.roles = ['test_role']
    m3.group_table_id = gt3.id
    m3.role_model_table_id = enrolled.id
    
    m4 = MembershipTable.new
    m4.roles = []
    m4.group_table_id = gt3.id
    m4.role_model_table_id = unenrolled.id
    [m1,m2,m3,m4].each(&:save!)
    [gt1, gt2, gt3]
  end

  describe "::visible_to" do
    it 'should return an active record relation' do
      expect(subject.visible_to(enrolled)).to be_an(ActiveRecord::Relation)
    end

    it 'should fetch all records that are visible to an actor' do
      expect(subject.visible_to(enrolled).length).to eq(2)
    end

    it 'should not fetch records invisible to an actor' do
      expect(subject.visible_to(unenrolled).length).to_not eq(3)
      expect(subject.visible_to(unenrolled).length).to eq(1)
    end

    it 'should fetch all publicly visible records for unenrolled actor' do
      test_user = Class.new{ include RoleControl::UnrolledUser }.new
      expect(subject.visible_to(test_user).length).to eq(1)
    end
  end

  describe "#check_read_roles" do
    it 'should return true when no visible_to roles are set' do
      expect(group_tables[0].check_read_roles(enrolled)).to be_truthy
    end

    it 'should return false when the actor has no required roles' do
      expect(group_tables[1].check_read_roles(unenrolled)).to be_falsy
    end

    it 'should return false when there is no intersection of roles' do
      expect(group_tables[2].check_read_roles(enrolled)).to be_falsy
    end

    it 'should return true when there is an intersection of roles' do
      expect(group_tables[1].check_read_roles(enrolled)).to be_truthy
    end
  end

  describe "#can_show?" do
    it 'should call #check_read_roles' do
      expect_any_instance_of(subject).to receive(:check_read_roles)
      subject.new.can_show?(enrolled)
    end
  end
end
