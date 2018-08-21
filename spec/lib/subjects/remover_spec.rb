require 'spec_helper'

RSpec.describe Subjects::Remover do
  let(:workflow) { create(:workflow_with_subjects) }
  let(:subject_set) do
    create(:subject_set_with_subjects, workflows: [workflow])
  end
  let(:subjects) { subject_set.subjects }
  let(:subject) { subjects.sample }
  let!(:linked_sws) do
    create(
      :subject_workflow_status,
      workflow: workflow,
      subject: subject,
      classifications_count: 0
    )
  end
  let(:panoptes_client) { instance_double(Panoptes::Client) }
  let(:remover) { Subjects::Remover.new(subject.id, panoptes_client) }

  describe "#cleanup" do
    describe "testing the client configuration" do
      it "should setup the panoptes client with the correct env" do
        expect(Panoptes::Client)
          .to receive(:new)
          .with(env: Rails.env)
        Subjects::Remover.new(subject.id)
      end
    end

    context "with a client test double testing the client configuration" do
      let(:discussions) { [] }

      before do
        allow(panoptes_client)
        .to receive(:discussions)
        .with(focus_id: subject.id, focus_type: "Subject")
        .and_return(discussions)
      end

      context "without a real subject" do
        let(:linked_sws) { nil }
        let(:subject) { double(id: 100) }

        it "should ignore non existant subject ids" do
          expect(remover.cleanup).to be_falsey
        end
      end

      it "should not remove a subject that has been classified" do
        create(:classification, subjects: [subject])
        expect(remover.cleanup).to be_falsey
      end

      it "should not remove a subject that has been collected" do
        create(:collection, subjects: [subject])
        expect(remover.cleanup).to be_falsey
      end

      context "with a talk discussions" do
        let(:discussions) { [{"dummy" => "discussion"}] }

        it "should not remove a subject that has been in a talk discussion" do
          expect(remover.cleanup).to be_falsey
        end
      end

      it "should remove a subject that has not been used" do
        remover.cleanup
        expect { Subject.find(subject.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "with a non-zero count sws record" do
        let(:linked_sws) do
          create(
            :subject_workflow_status,
            workflow: workflow,
            subject: subject,
            classifications_count: 10
          )
        end
        it "should not remove a subject that has a non-zero count a sws record" do
          expect(remover.cleanup).to be_falsey
        end
      end

      context "with a retired count sws record" do
        let(:linked_sws) do
          create(
            :subject_workflow_status,
            workflow: workflow,
            subject: subject,
            retired_at: Time.now,
            retirement_reason: :flagged
          )
        end
        it "should not remove a subject that has a retired sws record" do
          expect(remover.cleanup).to be_falsey
        end
      end

      it "should remove the associated set_member_subjects" do
        sms_ids = subject.set_member_subjects.map(&:id)
        remover.cleanup
        expect { SetMemberSubject.find(sms_ids) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should remove the associated media resources" do
        locations = subjects.map { |s| create(:medium, linked: s) }
        media_ids = subject.reload.locations.map(&:id)
        remover.cleanup
        expect { Medium.find(media_ids) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "notify cellect about the subject removal" do
        expect(NotifySubjectSelectorOfRetirementWorker)
          .to receive(:perform_async)
          .with(subject.id, workflow.id)
        remover.cleanup
      end
    end
  end
end
