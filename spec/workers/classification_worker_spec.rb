require 'spec_helper'

RSpec.describe ClassificationWorker do
  let(:classification_worker) { ClassificationWorker.new }

  describe "perform" do
    before(:each) do
      allow_any_instance_of(ClassificationLifecycle).to receive(:update_seen_subjects)
      allow_any_instance_of(ClassificationLifecycle).to receive(:dequeue_subject)
      allow_any_instance_of(ClassificationLifecycle).to receive(:publish_to_kafka)
      allow_any_instance_of(ClassificationLifecycle).to receive(:create_project_preference)
    end

    let(:classification) { create(:classification) }

    context ":update" do
      after(:each) do
        classification_worker.perform(classification.id, "update")
      end

      it 'should call publish to kafka' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:publish_to_kafka)
      end

    end

    context ":create" do
      after(:each) do
        classification_worker.perform(classification.id, "create")
      end

      it 'should call create_project_preferences' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:create_project_preference)
      end

      it 'should call publish to kafka' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:publish_to_kafka)
      end

      it 'should call classification count worker' do
        expect(ClassificationCountWorker).to receive(:perform_async).twice
      end

      context "when a user has seen the subjects before" do

        it 'should not call the classification count worker' do
          create(:user_seen_subject,
                 user: classification.user,
                 workflow: classification.workflow,
                 subject_ids: classification.subject_ids)
          expect(ClassificationCountWorker).to_not receive(:perform_async)
        end
      end

      context "when a user is anonymous" do

        let!(:classification) { create(:classification, user: nil) }

        it 'should call the classification count worker' do
          expect(ClassificationCountWorker).to receive(:perform_async).twice
        end

        context "when the classification has the already_seen metadata value" do
          let!(:classification) { create(:anonymous_already_seen_classification) }

          it 'should not call the classification count worker' do
            expect(ClassificationCountWorker).to_not receive(:perform_async)
          end
        end
      end
    end

    context "anything else" do
      it 'should raise an error' do
       expect do
         classification_worker.perform(classification.id, nil)
       end.to raise_error("Invalid Post-Classification Action")
      end
    end
  end
end
