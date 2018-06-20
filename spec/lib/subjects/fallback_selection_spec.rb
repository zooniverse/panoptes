require 'spec_helper'

describe Subjects::FallbackSelection do
  let(:user) { User.first }
  let(:workflow) { Workflow.first }
  let(:sms) { SetMemberSubject.all }
  let(:opts) { {} }
  let(:selector) { Subjects::FallbackSelection.new(workflow, 5, opts) }

  before do
    uploader = create(:user)
    created_workflow = create(:workflow_with_subject_sets)
    create_list(:subject, 25, project: created_workflow.project, uploader: uploader).each do |subject|
      create(:set_member_subject, subject: subject, subject_set: created_workflow.subject_sets.first)
    end
  end

  describe "#any_workflow_data" do
    let(:subject_set_id) { nil }
    let(:opts) { { limit: 5, subject_set_id: subject_set_id } }
    let(:expected_ids) do
      workflow.set_member_subjects.pluck("set_member_subjects.id")
    end
    let(:subject_ids) { selector.any_workflow_data }

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
