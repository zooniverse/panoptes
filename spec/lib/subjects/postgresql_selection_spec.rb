require 'spec_helper'

RSpec.describe Subjects::PostgresqlSelection do

  def update_sms_priorities
    SetMemberSubject.where(priority: nil).each_with_index do |sms, index|
      sms.update_column(:priority, index+1)
    end
  end

  describe "selection" do
    let(:user) { User.first }
    let(:workflow) { Workflow.first }
    let(:sms) { SetMemberSubject.all }
    let(:opts) { {} }
    subject { Subjects::PostgresqlSelection.new(workflow, user, opts) }

    before do
      uploader = create(:user)
      created_workflow = create(:workflow_with_subject_sets)
      create_list(:subject, 25, project: created_workflow.project, uploader: uploader).each do |subject|
        create(:set_member_subject, subject: subject, subject_set: created_workflow.subject_sets.first)
      end
    end

    describe "#select" do
      describe "random selection" do
        it_behaves_like "select for incomplete_project"

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

      context "grouped selection" do
        let(:subject_set_id) { workflow.subject_sets.first.id }
        let(:opts) { {subject_set_id: subject_set_id} }
        before do
          allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
        end

        it_behaves_like "select for incomplete_project"

        it 'should only select subjects in the specified group' do
          create(:user_seen_subject,
                 user: user,
                 subject_ids: sms.sample(5).map(&:subject_id),
                 workflow: workflow)
          result_ids = subject.select
          sms_subject_ids = SetMemberSubject.where(id: result_ids).pluck(:subject_set_id)
          expect(sms_subject_ids).to all( eq(subject_set_id) )
        end
      end

      describe "priority selection" do
        let(:ordered) { sms.order(priority: :asc).pluck(:id) }
        let(:limit) { ordered.size }
        let(:opts) { { limit: limit } }

        before do
          update_sms_priorities
          allow_any_instance_of(Workflow).to receive(:prioritized).and_return(true)
        end

        it_behaves_like "select for incomplete_project"

        it 'should select subjects in asc order of the priority field' do
          result = subject.select
          expect(result).to eq(ordered)
        end

        context "with order by param" do
          let(:opts) { { limit: ordered.size, order: :desc } }

          it 'should ignore any order param on the priority field' do
            result = subject.select
            expect(result).to eq(ordered)
          end
        end

        context "with 1 limit for prepend test" do
          let(:limit) { 1 }

          it 'should allow negative numbers to prepend the sort list' do
            sms_subject = create(:subject,project: workflow.project, uploader: user)
            sms = create(:set_member_subject, subject: sms_subject,
              subject_set: workflow.subject_sets.first, priority: -10.to_f)
            first_id = subject.select.first
            expect(first_id).to eq(sms.id)
          end
        end
      end

      describe "priority and grouped selection" do
        let(:opts) { { subject_set_id: subject_set_id } }
        let(:subject_set_id) { SubjectSet.first.id }
        let(:sms) { SetMemberSubject.where(subject_set_id: subject_set_id) }

        before do
          %i( prioritized grouped ).each do |method|
            allow_any_instance_of(Workflow).to receive(method).and_return(true)
          end
        end

        before do
          update_sms_priorities
          created_workflow = Workflow.first
          subject_set = created_workflow.subject_sets.last
          latest_priority = SetMemberSubject.where.not(priority: nil).order(priority: :desc).limit(1).pluck(:priority).first
          create_list(:subject, 12, project: created_workflow.project, uploader: User.first).each_with_index do |subject, index|
            create(:set_member_subject, priority: latest_priority+index+1, subject: subject, subject_set: subject_set)
          end
        end

        it_behaves_like "select for incomplete_project"

        it 'should only select subjects in the specified group' do
          result = subject.select
          ordered = sms.limit(result.length).order(priority: :asc).pluck(:id)
          expect(result).to eq(ordered)
        end
      end
    end

    describe "#any_workflow_data" do
      let(:subject_set_id) { nil }
      let(:opts) { { limit: 5, subject_set_id: subject_set_id } }
      let(:expected_ids) do
        workflow.set_member_subjects.pluck("set_member_subjects.id")
      end
      let(:subject_ids) { subject.any_workflow_data }

      it "should select some data from the workflow" do
        expect(expected_ids).to include(*subject_ids)
      end

      context "grouped workflow" do
        let(:subject_set_id) { SubjectSet.first.id }

        before do
          allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
        end

        it "should select some data from the group" do
          expect(expected_ids).to include(*subject_ids)
        end

        context "without a subject_set_id param" do
          let(:subject_set_id) { nil }

          it "should raise an error" do
            expect {
              subject_ids
            }.to raise_error(Subjects::Selector::MissingParameter)
          end
        end
      end
    end
  end
end
