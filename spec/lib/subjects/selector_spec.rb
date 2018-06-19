require 'spec_helper'

RSpec.describe Subjects::Selector do
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { create(:user) }
  let!(:smses) { create_list(:set_member_subject, 10, subject_set: subject_set).reverse }
  let(:params) { {} }

  subject { described_class.new(user, workflow, params) }

  describe "#get_subjects" do
    context "when the workflow doesn't have any subject sets" do
      it 'should raise an informative error' do
        allow_any_instance_of(Workflow).to receive(:subject_sets).and_return([])
        expect{subject.get_subjects}.to raise_error(
          Subjects::Selector::MissingSubjectSet,
          "no subject set is associated with this workflow"
        )
      end
    end

    context "when the subject sets have no data" do
      it 'should raise the an error' do
        allow_any_instance_of(Workflow)
          .to receive(:set_member_subjects).and_return([])
        message = "No data available for selection"
        expect {
          subject.get_subjects
        }.to raise_error(Subjects::Selector::MissingSubjects, message)
      end
    end

    context "normal selection" do
      it 'should request strategy selection', :aggregate_failures do
        selector = instance_double("Subjects::StrategySelection")
        expect(selector).to receive(:select).and_return([1])
        expect(Subjects::StrategySelection).to receive(:new).and_return(selector)
        subject.get_subjects
      end

      it 'should return the default subjects set size' do
        subjects = subject.get_subjects
        expect(subjects.length).to eq(10)
      end

      context "when the params page size is set as a string" do
        let(:size) { 2 }
        subject do
          params = { page_size: size }
          described_class.new(user, workflow, params, Subject.all)
        end

        it 'should return the page_size number of subjects' do
          subjects = subject.get_subjects
          expect(subjects.length).to eq(size)
        end
      end
    end

    context "when the database selection strategy returns an empty set" do
      before do
        allow_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select).and_return([])
        expect_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:any_workflow_data)
          .and_call_original
      end

      it 'should fallback to selecting some data' do
        subjects = subject.get_subjects
      end

      context "and the workflow is grouped" do
        let(:subject_set_id) { subject_set.id }
        let(:params) { { subject_set_id: subject_set_id } }

        it 'should fallback to selecting some grouped data' do
          allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
          subjects = subject.get_subjects
        end
      end
    end

    context "when the cellect selection strategy returns an empty set" do
      before do
        workflow.designator!
        stub_designator_client
      end

      it 'should fallback to using postgres selection' do
        expect_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select)
          .and_call_original
        subject.get_subjects
      end

      it "should notify cellect to reload" do
        Panoptes.flipper[:cellect_sync_error_reload].enable
        expect(NotifySubjectSelectorOfChangeWorker).to receive(:perform_async).with(workflow.id)
        subject.get_subjects
      end

      it "should not notify cellect to reload if the feature is disabled" do
        expect(NotifySubjectSelectorOfChangeWorker).not_to receive(:perform_async)
        subject.get_subjects
      end

      it "should notify us this sync error occurred" do
        expect(Honeybadger).to receive(:notify)
        subject.get_subjects
      end

      context "when the default postgres selector returns no data" do
        before do
          allow_any_instance_of(Subjects::PostgresqlSelection)
            .to receive(:select)
            .and_return([])
        end

        it "should fallback to just returning any data" do
          expect_any_instance_of(Subjects::PostgresqlSelection)
            .to receive(:any_workflow_data)
            .and_call_original
          subject.get_subjects
        end
      end
    end
  end

  describe '#selected_subjects' do

    it 'should not return deactivated subjects' do
      deactivated_ids = smses[0..smses.length-2].map(&:subject_id)
      Subject.where(id: deactivated_ids).update_all(activated_state: 1)
      result_ids = subject.selected_subjects.pluck(&:id)
      expect(result_ids).not_to include(*deactivated_ids)
    end

    it 'should return something when everything selected is retired' do
      smses.each do |sms|
        swc = create(:subject_workflow_status, subject: sms.subject, workflow: workflow, retired_at: Time.zone.now)
      end
      expect(subject.selected_subjects.size).to be > 0
    end

    it "should respect the order of the sms selection" do
      ordered_sms = smses.sample(5)
      sms_ids = ordered_sms.map(&:id)
      expect(subject).to receive(:run_strategy_selection).and_return(sms_ids)
      subjects = subject.selected_subjects
      expect(ordered_sms.map(&:subject_id)).to eq(subjects.map(&:id))
    end
  end
end
