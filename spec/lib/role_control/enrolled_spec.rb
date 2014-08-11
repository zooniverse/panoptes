require 'spec_helper'

describe RoleControl::Enrolled do
  setup_role_control_tables
  
  let(:subject) { RoleModelTable }
  
  describe "::roles_for" do
    it 'should can entry to the roles_for Hash' do
      subject.instance_eval { roles_for Object, :association, :roles_field }
      expect(subject.instance_variable_get(:@roles_for)[Object]).to eq([:association,
                                                                        :roles_field])
      
    end

    it 'should use :roles as the default name for the roles field' do
      subject.instance_eval { roles_for Object, :association }
      expect(subject.instance_variable_get(:@roles_for)[Object]).to eq([:association,
                                                                        :roles])
    end
  end

  describe "::roles_query_for" do
    let(:instance) { subject.new }
    let(:target) { GroupTable.new }

    before(:each) do
      instance.save!
      target.save!
      mt = MembershipTable.new(roles: ["test_role"])
      mt.role_model_table_id = instance.id
      mt.group_table_id = target.id
      mt.save!
    end

    it 'should return an AR relation' do
      expect(subject.roles_query_for(instance, target.class)).to be_a(ActiveRecord::Relation)
    end

    it 'should produce matching sql for a general class query' do
      sql = subject.roles_query_for(instance, target.class).to_sql
      matched_sql = /SELECT roles as roles, group_table_id FROM \"__membership_table\"  WHERE \"__membership_table\".\"role_model_table_id\" = (#{ instance.id }|\$1)/
      expect(sql).to match(matched_sql)
    end

    it 'should produce matching sql for a specific instance' do
      sql = subject.roles_query_for(instance, target.class, target.id).to_sql
      matched_sql = /SELECT roles as roles, group_table_id FROM \"__membership_table\"  WHERE \"__membership_table\".\"role_model_table_id\" = (#{ instance.id }|\$1) AND \"__membership_table\".\"group_table_id\" = #{ target.id }/
      expect(sql).to match(matched_sql)
    end

  end

  describe "#roles_query_for" do
    it 'should deletegate to the class method' do
      instance = subject.new
      target = double({ id: 1 })
      expect(subject).to receive(:roles_query_for)
        .with(instance, target.class, target.id)
      instance.roles_query_for(target)
    end
  end
end
