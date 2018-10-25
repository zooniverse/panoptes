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
    let(:sms_count) { 25 }
    subject { Subjects::PostgresqlSelection.new(workflow, user, opts) }

    before do
      uploader = create(:user)
      created_workflow = create(:workflow_with_subject_sets)
      create_list(:subject, sms_count, project: created_workflow.project, uploader: uploader).each do |subject|
        create(:set_member_subject,
          setup_subject_workflow_statuses: true,
          subject: subject,
          subject_set: created_workflow.subject_sets.first
        )
      end
    end

    describe "#select" do
      describe "random selection" do
        it_behaves_like "select for incomplete_project" do
          let(:sms_scope) do
            SetMemberSubject.all
          end
        end
      end

      context "grouped selection" do
        let(:subject_set_id) { workflow.subject_sets.first.id }
        let(:opts) { {subject_set_id: subject_set_id} }
        before do
          allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
        end

        it_behaves_like "select for incomplete_project" do
          let(:sms_scope) do
            SetMemberSubject.where(subject_set_id: subject_set_id)
          end
        end

        it 'should only select subjects in the specified group' do
          subject_ids = sms.sample(5).map(&:subject_id)
          create(:classification, user: user, workflow: workflow, subject_ids: subject_ids)
          create(:user_seen_subject,
                 user: user,
                 subject_ids: subject_ids,
                 workflow: workflow)
          result_ids = subject.select
          sms_subject_ids = SetMemberSubject.where(id: result_ids).pluck(:subject_set_id)
          expect(sms_subject_ids).to all( eq(subject_set_id) )
        end
      end

      describe "priority selection" do
        let(:ordered) { sms.order(priority: :asc).pluck(:subject_id) }
        let(:limit) { ordered.size }
        let(:opts) { { limit: limit } }

        before do
          update_sms_priorities
          allow_any_instance_of(Workflow).to receive(:prioritized).and_return(true)
        end

        it_behaves_like "select for incomplete_project" do
          let(:sms_scope) do
            SetMemberSubject.all
          end
        end
      end

      describe "priority and grouped selection" do
        let(:opts) { { subject_set_id: subject_set_id } }
        let(:subject_set_id) { SubjectSet.first.id }
        let(:sms) { SetMemberSubject.where(subject_set_id: subject_set_id) }
        let(:sms_count) { 37 }

        before do
          %i( prioritized grouped ).each do |method|
            allow_any_instance_of(Workflow).to receive(method).and_return(true)
          end
          update_sms_priorities
          created_workflow = Workflow.first
          subject_set = created_workflow.subject_sets.last
          latest_priority = SetMemberSubject.where.not(priority: nil).order(priority: :desc).limit(1).pluck(:priority).first
          create_list(:subject, 12, project: created_workflow.project, uploader: User.first).each_with_index do |subject, index|
            create(:set_member_subject, priority: latest_priority+index+1, subject: subject, subject_set: subject_set)
          end
        end

        it_behaves_like "select for incomplete_project" do
          let(:sms_scope) do
            SetMemberSubject.where(subject_set_id: subject_set_id)
          end
        end

        it 'should only select subjects in the specified group' do
          result = subject.select
          ordered = sms.limit(result.length).order(priority: :asc).pluck(:subject_id)
          expect(result).to eq(ordered)
        end
      end
    end
  end
end
