require 'spec_helper'

RSpec.describe RandomOrderShuffleWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:user) { workflow.project.owner }
  let(:subject_set) { workflow.subject_sets.first }
  let(:subjects) do
    create_list(:subject, 25, project: workflow.project, uploader: user).each do |subject|
      create(:set_member_subject, subject: subject, subject_set: subject_set)
    end
  end
  let(:set_member_subjects) { subjects.map { |s| s.set_member_subjects.first } }
  let(:set_member_subject_ids) { set_member_subjects.map(&:id) }
  let(:random_order) { set_member_subjects.map(&:random) }

  describe "#perform" do

    it "should reassign the random attribute of the sms ids" do
      expect do
        worker.perform(set_member_subject_ids)
      end.to change { set_member_subjects.map(&:reload).map(&:random) }
    end
  end
end
