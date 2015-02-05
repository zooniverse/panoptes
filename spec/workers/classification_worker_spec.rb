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
        classification_worker.perform(classification.id, :update)
      end

      it 'should call update_seen_subject' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:update_seen_subjects)
      end

      it 'should call dequeue_subject' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:dequeue_subject)
      end

      it 'should call publish to kafka' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:publish_to_kafka)
      end

    end

    context ":create" do
      after(:each) do
        classification_worker.perform(classification.id, :create)
      end

      it 'should call create_project_preferences' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:create_project_preference)
      end

      it 'should call update_seen_subject' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:update_seen_subjects)
      end

      it 'should call dequeue_subject' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:dequeue_subject)
      end

      it 'should call publish to kafka' do
        expect_any_instance_of(ClassificationLifecycle).to receive(:publish_to_kafka)
      end
    end
  end
end
