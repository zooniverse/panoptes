require 'spec_helper'

RSpec.describe ClassificationWorker do
  let(:classification_worker) { ClassificationWorker.new }

  describe "perform" do
    let(:classification) { create(:classification) }

    context ":update" do
      after(:each) do
        classification_worker.perform(classification.id, "update")
      end

      it "should call transact! on the lifecycle" do
        expect_any_instance_of(ClassificationLifecycle).to receive(:transact!)
      end

      context "when the lifecycled_at field is set" do
        let(:classification) do
          create(:classification, lifecycled_at: Time.zone.now)
        end

        it "should not abort the worker" do
          expect_any_instance_of(ClassificationLifecycle).to receive(:transact!)
        end
      end
    end

    context ":create" do
      after(:each) do
        classification_worker.perform(classification.id, "create")
      end

      it "should call transact! on the lifecycle" do
        expect_any_instance_of(ClassificationLifecycle).to receive(:transact!)
      end

      it 'should call process_project_preferences' do
        expect_any_instance_of(ClassificationLifecycle)
        .to receive(:process_project_preference)
      end

      it 'should call classification count worker' do
        expect(ClassificationCountWorker)
        .to receive(:perform_async).twice
      end

      context "when the lifecycled_at field is set" do
        let(:classification) do
          create(:classification, lifecycled_at: Time.zone.now)
        end

        it "should abort the worker asap" do
          expect_any_instance_of(ClassificationLifecycle)
          .not_to receive(:transact!)
        end
      end

      context "when a user has seen the subjects before" do
        it 'should not call the classification count worker' do
          create(:user_seen_subject,
                 user: classification.user,
                 workflow: classification.workflow,
                 subject_ids: classification.subject_ids)
          expect(ClassificationCountWorker)
          .to_not receive(:perform_async)
        end
      end

      context "when a user is anonymous" do
        let(:classification) { create(:classification, user: nil) }

        it 'should call the classification count worker' do
          expect(ClassificationCountWorker)
          .to receive(:perform_async).twice
        end

        context "when the classification has the already_seen metadata value" do
          let!(:classification) do
            create(:anonymous_already_seen_classification)
          end

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
