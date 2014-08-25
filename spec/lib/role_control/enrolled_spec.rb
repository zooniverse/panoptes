require 'spec_helper'

describe RoleControl::Enrolled do
  setup_role_control_tables
  
  let(:subject) { EnrolledTable }
  let(:instance) { subject.new }
  let(:target) { ControlledTable.new }

  before(:each) do
    instance.save!
    target.save!
    create_role_model_instance(%w(test_role), target, instance)
  end
  
  describe "::enrolled_for" do
    before(:each) do
      subject.instance_eval { enrolled_for :objects, through: :association }
    end
    
    it 'should add an entry to the enrolled_for hash' do
      expect(subject.instance_variable_get(:@enrolled_for)[Object])
        .to eq(:association)
    end

    it 'should define a method based on the supplied controlled relation' do
      expect(subject.new).to respond_to(:objects_for)
    end
  end

  describe "::roles_for" do
    it 'should return an AR relation' do
      expect(subject.roles_for(instance, target)).to be_a(ActiveRecord::Relation)
    end
  end

  describe "#roles_for" do
    let(:roles_for) { instance.roles_for(target) }
    it 'should call the roles_query instance method' do
      expect(instance).to receive(:roles_query).with(target).and_return([])
      roles_for
    end

    it 'should return an array of roles' do
      expect(roles_for).to eq(["test_role"])
    end
  end

  describe "#roles_query" do
    let(:roles_query) { instance.roles_query(target) }
    
    it 'should call the class roles_for method' do
      expect(EnrolledTable).to receive(:roles_for).with(instance, target)
      roles_query
    end

    it 'should return an active_record relation' do
      expect(roles_query).to be_an(ActiveRecord::Relation)
    end
  end
end
