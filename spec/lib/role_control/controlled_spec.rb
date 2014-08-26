require 'spec_helper'

describe RoleControl::Controlled do
  setup_role_control_tables
  
  let(:subject) { ControlledTable }
  
  let(:controlled) do
    subject.create! do |s|
      s.visible_to = [ "test_role" ]
    end
  end
  
  let(:enrolled_actor) { EnrolledActorTable.create! }
  
  let(:unenrolled_actor) { EnrolledActorTable.create! }

  describe "::can_create?" do
    it 'should return truthy when passed a non-nil value' do
      expect(subject.can_create?(Object.new)).to be_truthy
    end

    it 'should return falsy when passed a nil value' do
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
      
      create_roles_join_instance(%w(admin), gt1, enrolled_actor)
      create_roles_join_instance(%w(test_role), gt2, enrolled_actor)
      create_roles_join_instance(%w(test_role), gt3, enrolled_actor)
      create_roles_join_instance([], gt3, unenrolled_actor)
      
      [gt1, gt2, gt3]
    end

    it 'should return an active record relation' do
      expect(subject.scope_for(:read, enrolled_actor)).to be_an(ActiveRecord::Relation)
    end

    it 'should fetch all records that are visible to an actor' do
      visible_records = subject.scope_for(:read, enrolled_actor)
      expected_records = group_tables.values_at(0,1)
      expect(visible_records).to match_array(expected_records)
    end

    it 'should not fetch records that the unenrolled actor has no roles on' do
      visible_records = subject.scope_for(:read, unenrolled_actor)
      no_roles_instance = group_tables.values_at(2)
      expect(visible_records).not_to include(no_roles_instance)
    end

    it 'should fetch all publicly visible records for unenrolled actor' do
      test_user = Class.new{ include RoleControl::UnrolledUser }.new
      
      visible_records = subject.scope_for(:read, test_user)
      expected_records = group_tables.values_at(0)
      expect(visible_records).to match_array(expected_records)
    end
  end

  describe "::can_by_role" do
    before(:each) do
      create_roles_join_instance(%w(test_role), controlled, enrolled_actor)
      create_roles_join_instance([], controlled, unenrolled_actor)
    end
    
    it 'should create an instance method to test the action' do 
      expect(controlled).to respond_to(:can_read?)
    end

    it 'should create a proc to test when roles are present' do
      subject.instance_eval { can_by_role :edit, roles: [:test_role] }
      expect(subject.instance_variable_get(:@can_filters)[:edit].first).to be_a(Proc)
    end

    it 'should return truthy when passed an enrolled object with roles' do
      expect(controlled.can_read?(enrolled_actor)).to be_truthy
    end

    it 'should return falsy when passed an unenrolled object with no roles' do
      expect(controlled.can_read?(unenrolled_actor)).to be_falsy
    end
  end
end
