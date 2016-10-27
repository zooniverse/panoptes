require 'spec_helper'

RSpec.describe Subjects::PostgresqlRandomSelection do
  let(:available) { SetMemberSubject.all }
  let(:limit) { 10 }
  let(:available_count) { 25 }
  subject { Subjects::PostgresqlRandomSelection.new(available, limit) }

  before do
    uploader = create(:user)
    created_workflow = create(:workflow_with_subject_sets)
    subjects = create_list(:subject, available_count, project: created_workflow.project, uploader: uploader)
    subjects.each do |subject|
      create(:set_member_subject, subject: subject, subject_set: created_workflow.subject_sets.first)
    end
  end

  describe "random selection" do
    it "should reassign the random attribute after selection" do
      allow(Panoptes::SubjectSelection).to receive(:index_rebuild_rate).and_return(1)
      expect(RandomOrderShuffleWorker).to receive(:perform_async).once
      subject.select
    end

    describe "selection limits" do

      context "larger than half available count" do
        let(:limit) { 20 }

        it 'should return limit size' do
          results = subject.select
          expect(results.length).to eq(limit)
        end
      end

      context "smaller than half available count" do
        let(:limit) { 10 }

        it 'should return limit size' do
          results = subject.select
          expect(results.length).to eq(limit)
        end
      end
    end
  end
end
