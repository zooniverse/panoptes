require 'spec_helper'

RSpec.describe Subjects::PostgresqlRandomSelection do
  let(:available) { SetMemberSubject.all }
  subject { Subjects::PostgresqlRandomSelection.new(available, 10) }

  before do
    uploader = create(:user)
    created_workflow = create(:workflow_with_subject_sets)
    create_list(:subject, 25, project: created_workflow.project, uploader: uploader).each do |subject|
      create(:set_member_subject, subject: subject, subject_set: created_workflow.subject_sets.first)
    end
  end

  describe "random selection" do
    it "should reassign the random attribute after selection" do
      allow(Panoptes::SubjectSelection).to receive(:index_rebuild_rate).and_return(1)
      expect(RandomOrderShuffleWorker).to receive(:perform_async).once
      subject.select
    end

    it "should give up trying to construct a random list after set number of attempts" do
      unreachable_limit = SetMemberSubject.count + 1
      allow_any_instance_of(subject.class).to receive(:available_count).and_return(unreachable_limit + 1)
      allow_any_instance_of(subject.class).to receive(:limit).and_return(unreachable_limit)
      results = subject.select
      expect(results).to eq(results)
    end
  end
end
