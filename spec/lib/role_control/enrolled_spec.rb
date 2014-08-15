require 'spec_helper'

describe RoleControl::Enrolled do
  setup_role_control_tables
  
  let(:subject) { EnrolledTable }
  let(:instance) { subject.new }
  let(:target) { ControlledTable.new }

  before(:each) do
    instance.save!
    target.save!
    mt = RoleModelTable.new(roles: ["test_role"])
    mt.enrolled_table = instance
    mt.controlled_table = target
    mt.save!
  end
  
  describe "::enrolled_for" do
    before(:each) do
      subject.instance_eval { enrolled_for :objects, through: :association }
    end
    
    it 'should can entry to the enrolled_for hash' do
      expect(subject.instance_variable_get(:@enrolled_for)[Object])
        .to eq(:association)
    end

    it 'should define a method based on the supplied controlled relation' do
      expect(subject.new).to respond_to(:objects)
    end
  end

  describe "::roles_for" do
    it 'should return an AR relation' do
      expect(subject.roles_for(instance, target)).to be_a(ActiveRecord::Relation)
    end
  end

  describe "#roles_for" do
    it 'should deletegate to the instance method' do
      expect(instance).to receive(:roles_query).with(target)
      instance.roles_for(target)
    end

    it 'should return an array of roles' do
      expect(instance.roles_for(target)).to eq(["test_role"])
    end
  end
end
