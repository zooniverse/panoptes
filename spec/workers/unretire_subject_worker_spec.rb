require 'spec_helper'

RSpec.describe UnretireSubjectWorker do
    let(:worker) { described_class.new }
    let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
    let(:subject) { workflow.subjects.first }
    let(:sms) { subject.set_member_subject.first }
    let(:set) { sms.subject_set }
    let(:status) { create(:subject_workflow_status, subject: subject, workflow: workflow, retired_at: 1.days.ago, retirement_reason: 'other') }

    describe "#perform" do 
        context "is unretireable" do 
            it "should set retired_at to nil", :focus => true do 
                expect{ worker.perform(workflow.id, [ subject.id ] ) }.to change {
                    status.reload.retired_at
            }.to(nil)
            end
        end
    end
end