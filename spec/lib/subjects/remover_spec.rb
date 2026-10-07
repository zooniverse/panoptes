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

  describe 'explicit hard deletion' do
    it 'removes a used subject and its links, preserving classifications and collections' do
      classification = create(:classification, subjects: [subject])
      collection = create(:collection, subjects: [subject], default_subject: subject)
      recent = create(:recent, subject: subject, classification: classification)
      linked_sws.update!(classifications_count: 5, retired_at: Time.current)

      remover.cleanup(hard_delete: true)

      expect(Subject.where(id: subject.id)).not_to exist
      expect(classification.reload.subjects).to be_empty
      expect(collection.reload.subjects).to be_empty
      expect(collection.subjects_count).to eq(0)
      expect(collection.default_subject_id).to be_nil
      expect(SetMemberSubject.where(subject_id: subject.id)).not_to exist
      expect(SubjectWorkflowStatus.where(id: linked_sws.id)).not_to exist
      expect(Recent.where(id: recent.id)).not_to exist
    end

    it 'uses the existing media removal callback for locations and attached images' do
      location = create(:medium, linked: subject)
      image = create(:medium, linked: subject, type: 'subject_attached_image')
      external = create(:medium, linked: subject, external_link: true)
      Sidekiq::Worker.clear_all

      remover.cleanup(hard_delete: true)

      expect(Medium.where(id: [location.id, image.id, external.id])).not_to exist
      expect(MediumRemovalWorker.jobs.map { |job| job['args'].first }).to match_array([location.src, image.src])
    end

    it 'does not enqueue storage removal when subject deletion rolls back' do
      location = create(:medium, linked: subject)
      collection = create(:collection, subjects: [subject])
      tutorial_workflow = create(:workflow, tutorial_subject: subject)
      allow_any_instance_of(Subject).to receive(:delete).and_raise(ActiveRecord::StatementInvalid)

      expect { remover.cleanup(hard_delete: true) }.to raise_error(ActiveRecord::StatementInvalid)

      expect(subject.reload).to be_persisted
      expect(location.reload).to be_persisted
      expect(collection.reload.subjects).to include(subject)
      expect(tutorial_workflow.reload.tutorial_subject_id).to eq(subject.id)
      expect(MediumRemovalWorker.jobs).to be_empty
    end

    it 'retries media enqueueing even after the subject has been deleted' do
      location = create(:medium, linked: subject)
      allow(MediumRemovalWorker).to receive(:perform_async).and_raise(Timeout::Error)

      expect { remover.cleanup(hard_delete: true) }.to raise_error(Timeout::Error)
      expect(Subject.where(id: subject.id)).not_to exist
      expect(location.reload).to be_persisted

      allow(MediumRemovalWorker).to receive(:perform_async).and_call_original
      remover.cleanup(hard_delete: true)

      expect(Medium.where(id: location.id)).not_to exist
      expect(MediumRemovalWorker.jobs.last['args'].first).to eq(location.src)
    end

    it 'clears tutorial references while preserving the workflow' do
      tutorial_workflow = create(:workflow, tutorial_subject: subject)

      remover.cleanup(hard_delete: true)

      expect(tutorial_workflow.reload.tutorial_subject_id).to be_nil
      expect(Subject.where(id: subject.id)).not_to exist
    end

    it 'clears gold-standard references while preserving annotation data' do
      connection = Subject.connection
      annotation_id = connection.select_value <<-SQL
        INSERT INTO gold_standard_annotations (subject_id, annotations, metadata, created_at, updated_at)
        VALUES (#{connection.quote(subject.id)}, '{"answer":42}', '{}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING id
      SQL

      remover.cleanup(hard_delete: true)

      annotation = connection.select_one("SELECT subject_id, annotations FROM gold_standard_annotations WHERE id = #{connection.quote(annotation_id)}")
      expect(annotation['subject_id']).to be_nil
      expect(JSON.parse(annotation['annotations'])).to eq('answer' => 42)
      expect(Subject.where(id: subject.id)).not_to exist
    end

    it 'removes legacy recents only for the deleted subject' do
      connection = Subject.connection
      other_subject = create(:subject)
      [subject.id, other_subject.id].each do |id|
        connection.execute <<-SQL
          INSERT INTO recents_old (subject_id, created_at, updated_at)
          VALUES (#{connection.quote(id)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        SQL
      end

      remover.cleanup(hard_delete: true)

      expect(connection.select_value("SELECT COUNT(*) FROM recents_old WHERE subject_id = #{connection.quote(subject.id)}").to_i).to eq(0)
      expect(connection.select_value("SELECT COUNT(*) FROM recents_old WHERE subject_id = #{connection.quote(other_subject.id)}").to_i).to eq(1)
    end

    it 'preserves other subjects and their classification, collection, and media links' do
      other_subject = create(:subject)
      classification = create(:classification, subjects: [subject, other_subject])
      collection = create(:collection, subjects: [subject, other_subject], default_subject: other_subject)
      other_media = create(:medium, linked: other_subject)

      remover.cleanup(hard_delete: true)

      expect(classification.reload.subject_ids).to eq([other_subject.id])
      expect(collection.reload.subject_ids).to eq([other_subject.id])
      expect(collection.subjects_count).to eq(1)
      expect(collection.default_subject_id).to eq(other_subject.id)
      expect(other_media.reload).to be_persisted
    end

    it 'clears cover references even when the subject is not a collection member' do
      collection = create(:collection, default_subject: subject)

      remover.cleanup(hard_delete: true)

      expect(collection.reload.default_subject_id).to be_nil
      expect(Subject.where(id: subject.id)).not_to exist
    end

    it 'cleans remaining attached images when a retry starts after subject deletion' do
      image = create(:medium, linked: subject, type: 'subject_attached_image')
      linked_sws.delete
      subject.delete

      remover.cleanup(hard_delete: true)

      expect(Medium.where(id: image.id)).not_to exist
      expect(MediumRemovalWorker.jobs.last['args'].first).to eq(image.src)
    end

    it 'bypasses Talk and other-set checks only for explicit hard deletion' do
      create(:set_member_subject, subject: subject)
      expect(panoptes_client).not_to receive(:discussions)

      expect(remover.cleanup(hard_delete: true)).to be(true)
    end

    it 'notifies existing selector and counter workers' do
      expect(NotifySubjectSelectorOfRetirementWorker).to receive(:perform_async).with(subject.id, workflow.id)
      expect(SubjectSetSubjectCounterWorker).to receive(:perform_async).with(subject_set.id)
      expect(WorkflowRetiredCountWorker).to receive(:perform_async).with(workflow.id)

      remover.cleanup(hard_delete: true)
    end

    it 'is safe to repeat once the subject and media are gone' do
      remover.cleanup(hard_delete: true)

      expect { remover.cleanup(hard_delete: true) }.not_to raise_error
    end
  end

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
          .with({ focus_id: subject.id, focus_type: "Subject" })
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

      context 'when subject_set_id is param in init' do
        let(:remover_with_subject_set) {
          described_class.new(subject.id, panoptes_client, subject_set.id)
        }

        it 'removes a subject that has not been used' do
          remover_with_subject_set.cleanup
          expect { Subject.find(subject.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'does not remove a subject that has been classified' do
          create(:classification, subjects: [subject])
          expect(remover_with_subject_set.cleanup).to be_falsey
        end

        context 'with multiple subject sets' do
          let(:alternate_subject_set) { create(:subject_set) }
          let(:remover) { described_class.new(subject.id, panoptes_client, alternate_subject_set.id) }
          let(:new_sms) { create(:set_member_subject, subject: subject, subject_set: alternate_subject_set) }

          it 'does not remove subjects associated with multiple set_member_subjects' do
            remover.cleanup
            expect(Subject.where(id: subject.id)).to exist
          end
        end
      end

      it "should remove the associated media resources" do
        locations = subjects.map { |s| create(:medium, linked: s) }
        media_ids = subject.reload.locations.map(&:id)
        remover.cleanup
        expect { Medium.find(media_ids) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "notify selector service about the subject removal" do
        expect(NotifySubjectSelectorOfRetirementWorker)
          .to receive(:perform_async)
          .with(subject.id, workflow.id)
        remover.cleanup
      end
    end
  end
end
