require 'spec_helper'

describe Workflows::RetireSubjects do
  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:workflow) { create(:workflow) }
  let(:subject_set) { create(:subject_set, project: workflow.project, workflows: [workflow]) }
  let(:subject_set_id) { subject_set.id }
  let(:subject1) { create(:subject, subject_sets: [subject_set]) }

  let(:operation) { described_class.with(api_user: api_user) }

  it "should call the retire subject worker with the subject_id" do
    expect(RetireSubjectWorker)
      .to receive(:perform_async)
      .with(workflow.id, [ subject1.id ], "other")
    operation.run! workflow: workflow, subject_id: subject1.id, retirement_reason: "other"
  end

  it "should call the retire subject worker with the subject_ids" do
    subject2 = create(:subject, subject_sets: [subject_set])
    subject_ids = [subject1.id, subject2.id]
    expect(RetireSubjectWorker)
      .to receive(:perform_async)
      .with(workflow.id, subject_ids, nil)
    operation.run! workflow: workflow, subject_ids: subject_ids
  end

  it 'rewrites the reason blank to nothing here' do
    expect(RetireSubjectWorker)
      .to receive(:perform_async)
      .with(workflow.id, [subject1.id], "nothing_here")
    operation.run! workflow: workflow, subject_id: subject1.id, retirement_reason: "blank"
  end

  it 'is invalid with an invalid retirement reason' do
    result = operation.run workflow: workflow, subject_id: subject1.id, retirement_reason: "nope"
    expect(result).not_to be_valid
  end

  it 'is valid with a missing parameter' do
    result = operation.run workflow: workflow, subject_id: subject1.id
    expect(result).to be_valid
  end
end
