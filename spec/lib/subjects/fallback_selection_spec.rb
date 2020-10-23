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
    first_set = created_workflow.subject_sets.first
    second_set = created_workflow.subject_sets.last
    # split the subjects across the sets
    create_list(:subject, 15, project: created_workflow.project, uploader: uploader).each do |subject|
      create(:set_member_subject, subject: subject, subject_set: first_set)
    end
    create_list(:subject, 10, project: created_workflow.project, uploader: uploader).each do |subject|
      create(:set_member_subject, subject: subject, subject_set: second_set)
    end
  end

  describe "#any_workflow_data" do
    let(:subject_set_id) { nil }
    let(:request_limit) { 5 }
    let(:opts) { { limit: request_limit, subject_set_id: subject_set_id } }
    let(:expected_ids) do
      workflow.set_member_subjects.pluck("set_member_subjects.subject_id")
    end
    let(:subject_ids) { selector.any_workflow_data }

    it "should select some data from the workflow" do
      expect(expected_ids).to include(*subject_ids)
    end

    context 'with training sets on the workflow' do
      let(:training_set_id) { [workflow.subject_set_ids.sample] }
      let(:training_subject_ids) do
        SetMemberSubject.where(subject_set_id: training_set_id).pluck(:subject_id)
      end

      before do
        allow(workflow).to receive(:training_set_ids).and_return(training_set_id)
      end

      it 'includes some training subject ids from the workflow' do
        selected_training_subject_ids = training_subject_ids & subject_ids
        expect(selected_training_subject_ids).not_to be_empty
      end

      it 'returns the correct number of subjects' do
        expect(subject_ids.count).to eq(request_limit)
      end
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
