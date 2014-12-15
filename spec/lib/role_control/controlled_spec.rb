require 'spec_helper'

describe RoleControl::Controlled do
  setup_role_control_tables
  
  let(:subject) { ControlledTable }
  
  let(:enrolled_actor) { EnrolledActorTable.create! }
  
  let(:unenrolled_actor) { EnrolledActorTable.create! }

  describe "::scope_for" do
    let!(:group_tables) do
      gt1 = subject.new(private: false)
      gt2 = subject.new
      gt3 = subject.new

      [gt1,gt2,gt3].each(&:save!)
      
      create_roles_join_instance(%w(admin), gt1, enrolled_actor)
      create_roles_join_instance(%w(test_role), gt2, enrolled_actor)
      create_roles_join_instance([], gt3, enrolled_actor)
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
      visible_records = subject.scope_for(:read, unenrolled_actor)
      expected_records = group_tables.values_at(0)
      expect(visible_records).to match_array(expected_records)
    end
  end

  describe "::can_by_role" do
    it 'should define an object that can be used by scope_for' do
      subject.can_by_role :edit,
                          public: :pub_scope,
                          role_association: :assoc,
                          roles: [ :a_role, :another ]

      expect(subject.roles(:edit)).to include(:pub_scope,
                                              :assoc,
                                              [ :a_role, :another ])
    end
  end
end
