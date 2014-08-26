require 'spec_helper'

describe RoleControl::RoleQuery do
  setup_role_control_tables
  
  def fake_rel(name)
    double({ klass: double({ model_name: double({ singular: name }) }) })
  end

  let(:fake_actor_rel) { fake_rel('actor') }
  let(:fake_resource_rel) { fake_rel('resource') }
  
  let(:instance) do
    RoleControl::RoleQuery.new(fake_actor_rel, fake_resource_rel, :roles, RolesJoinTable)
  end

  let(:actor) { EnrolledActorTable.create! }
  let(:resources) { [ControlledTable.create!] }

  describe "#build" do
    let(:built_query) { instance.build(actor, resources) }
    
    it 'should return an ActiveRecord::Relation' do
      expect(built_query).to be_an(ActiveRecord::Relation)
    end

    it 'should generate a sql query with a where eq when resources has length 1' do
      sql_string = "SELECT \"__roles_join_table\".\"roles\" AS roles, \"__roles_join_table\".\"resource_id\", \"__roles_join_table\".\"actor_id\" FROM \"__roles_join_table\"  WHERE \"__roles_join_table\".\"actor_id\" = #{ actor.id } AND \"__roles_join_table\".\"resource_id\" = #{ resources.first.id }"
      expect(built_query.to_sql).to eq(sql_string)
    end

    it 'should not include the actor where test when no actor is supplied' do
      sql_string = "SELECT \"__roles_join_table\".\"roles\" AS roles, \"__roles_join_table\".\"resource_id\", \"__roles_join_table\".\"actor_id\" FROM \"__roles_join_table\"  WHERE \"__roles_join_table\".\"resource_id\" = #{ resources.first.id }"
      expect(instance.build(nil, resources).to_sql).to eq(sql_string)
    end

    it 'should use a where in statement when there are multiple resources' do
      resources = []
      4.times { resources << ControlledTable.create! }
      
      sql_string = "SELECT \"__roles_join_table\".\"roles\" AS roles, \"__roles_join_table\".\"resource_id\", \"__roles_join_table\".\"actor_id\" FROM \"__roles_join_table\"  WHERE \"__roles_join_table\".\"actor_id\" = #{ actor.id } AND \"__roles_join_table\".\"resource_id\" IN (#{ resources.map(&:id).join(', ') })"
      expect(instance.build(actor, resources).to_sql).to eq(sql_string)
    end

    it 'should not include the resource where test when no resources are supplied' do
      sql_string = "SELECT \"__roles_join_table\".\"roles\" AS roles, \"__roles_join_table\".\"resource_id\", \"__roles_join_table\".\"actor_id\" FROM \"__roles_join_table\"  WHERE \"__roles_join_table\".\"actor_id\" = #{ actor.id }"
      expect(instance.build(actor, nil).to_sql).to eq(sql_string)
    end
  end
end
