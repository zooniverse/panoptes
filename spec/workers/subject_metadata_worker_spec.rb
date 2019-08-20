require "spec_helper"

RSpec.describe SubjectMetadataWorker do
  let(:user) { create :user }
  let(:project) { create :project_with_workflow, owner: user }
  let(:workflow) { project.workflows.first }
  let(:subject_set) do
    create(:subject_set_with_subjects, num_subjects: 3, project: project, workflows: [workflow])
  end

  subject(:worker) { SubjectMetadataWorker.new }

  before do
    subject_set.subjects[0].metadata['#priority'] = 1/3.0
    subject_set.subjects[1].metadata['#priority'] = "2"
    subject_set.subjects.map(&:save)
  end

  describe "#perform" do
    # TODO: Rails 5 combine the tests to one
    # to test behaviour not AR calling interface
    it 'calls the correct RAILS 5 AR methods' do
      stub_const("ActiveRecord::VERSION::MAJOR", 5)
      expect(ActiveRecord::Base.connection)
        .to receive(:exec_update)
        .with(instance_of(String), "SQL",[[nil, subject_set.id]])
      worker.perform(subject_set.id)
    end

    it 'copies priority from metadata to SMS attribute' do
      worker.perform(subject_set.id)
      sms_one, sms_two, sms_three = SetMemberSubject.find(
        subject_set.set_member_subject_ids
      ).sort_by(&:id)
      expect(sms_one.priority).to eq(1/3.0)
      expect(sms_two.priority).to eq(2)
      expect(sms_three.priority).to be_nil
    end
  end
end
