require 'spec_helper'

RSpec.describe Subjects::Selector do
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { create(:user) }
  let!(:smses) do
    create_list(
      :set_member_subject,
      10,
      setup_subject_workflow_statuses: true,
      subject_set: subject_set
    ).reverse
  end
  let(:params) { { workflow_id: workflow.id } }

  subject { described_class.new(user, params) }

  describe "#get_subject_ids" do
    context "without a workflow_id param" do
      let(:params) { {} }

      it 'should raise a missing param error' do
        expect{subject.get_subject_ids}.to raise_error(
          Subjects::Selector::MissingParameter,
          "workflow_id parameter missing"
        )
      end
    end

    context "when the workflow doesn't have any subject sets" do
      it 'should raise an informative error' do
        allow_any_instance_of(Workflow).to receive(:subject_sets).and_return([])
        expect{subject.get_subject_ids}.to raise_error(
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
          subject.get_subject_ids
        }.to raise_error(Subjects::Selector::MissingSubjects, message)
      end
    end

    context "normal selection" do
      it 'should request strategy selection', :aggregate_failures do
        selector = instance_double("Subjects::StrategySelection")
        expect(selector).to receive(:select).and_return([1])
        expect(Subjects::StrategySelection).to receive(:new).and_return(selector)
        subject.get_subject_ids
      end

      it 'should return the default subjects set size' do
        subjects = subject.get_subject_ids
        expect(subjects.length).to eq(10)
      end

      describe "page_size" do
        context "when params is set as a string" do
          let(:size) { 2 }
          subject do
            params = { page_size: size, workflow_id: workflow.id }
            described_class.new(user, params)
          end

          it 'should return the page_size number of subjects' do
            subjects = subject.get_subject_ids
            expect(subjects.length).to eq(size)
          end
        end

        context "when the workflow config has subject_queue_page_size set" do
          let(:params_page_size) { 2 }
          let(:subject_queue_page_size) { 1 }
          let(:config) { { subject_queue_page_size: subject_queue_page_size }}
          let(:workflow) do
            create(:workflow_with_subject_set, configuration: config)
          end

          subject do
            described_class.new(user, params)
          end

          context "when params page_size is missing" do
            let(:params) { { workflow_id: workflow.id } }

            it 'should respect the config page_size value' do
              subjects = subject.get_subject_ids
              expect(subjects.length).to eq(subject_queue_page_size)
            end
          end

          context "when params page_size is set" do
            let(:params) { { page_size: params_page_size, workflow_id: workflow.id } }

            it 'should respect the params page_size value' do
              subjects = subject.get_subject_ids
              expect(subjects.length).to eq(params_page_size)
            end
          end
        end
      end
    end

    context "when the database selection strategy returns an empty set" do
      before do
        allow_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select).and_return([])
        expect_any_instance_of(Subjects::FallbackSelection)
          .to receive(:any_workflow_data)
          .and_call_original
      end

      it 'returns data from the fallback selector' do
        subjects = subject.get_subject_ids
      end

      context "and the workflow is grouped" do
        let(:subject_set_id) { subject_set.id }
        let(:params) do
          {
            subject_set_id: subject_set_id,
            workflow_id: workflow.id
          }
        end

        it 'returns grouped data from the fallback selector' do
          allow_any_instance_of(Workflow).to receive(:grouped).and_return(true)
          subjects = subject.get_subject_ids
        end
      end
    end

    context "when the selection strategy returns an empty set" do
      before do
        workflow.designator!
        stub_designator_client
      end

      it 'uses postgres selection' do
        expect_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select)
          .and_call_original
        subject.get_subject_ids
      end

      it "should notify selector to reload" do
        Panoptes.flipper[:selector_sync_error_reload].enable
        expect(NotifySubjectSelectorOfChangeWorker).to receive(:perform_async).with(workflow.id)
        subject.get_subject_ids
      end

      it "should not notify selector to reload if the feature is disabled" do
        expect(NotifySubjectSelectorOfChangeWorker).not_to receive(:perform_async)
        subject.get_subject_ids
      end

      context 'when the postgres selector returns no data' do
        before do
          allow_any_instance_of(Subjects::PostgresqlSelection)
            .to receive(:select)
            .and_return([])
        end

        it 'uses the fallback selector and returns any data' do
          expect_any_instance_of(Subjects::FallbackSelection)
            .to receive(:any_workflow_data)
            .and_call_original
          subject.get_subject_ids
        end
      end
    end
  end

  describe '#selected_subject_ids' do
    it 'should return something when everything selected is retired' do
      SubjectWorkflowStatus.where(
        subject_id: smses.map(&:subject_id),
        workflow_id: workflow.id
      ).update_all(
        retired_at: Time.zone.now
      )
      expect(subject.selected_subject_ids.size).to be > 0
    end

    it "should respect the order of the subjects from strategy selector" do
      ordered_sms = smses.sample(5)
      subject_ids = ordered_sms.map(&:subject_id)
      allow_any_instance_of(
        Subjects::StrategySelection
      ).to receive(:select).and_return(subject_ids)
      retured_subject_ids = subject.selected_subject_ids
      expect(subject_ids).to eq(retured_subject_ids)
    end

    it 'does not allow sql injection' do
      hacking_attempt = [1, 2, '1], set_member_subjects.id); DROP TABLE users; -- ']
      expect(subject).to receive(:run_strategy_selection).and_return(hacking_attempt)
      expect {
        subject.selected_subject_ids
      }.to raise_error(
        Subjects::Selector::MalformedSelectedIds,
        "Selector returns non-integers, hacking attempt?!"
      )
    end
  end

  describe "selection_state" do
    it "should default respond with normal" do
      subject.get_subject_ids
      expect(subject.selection_state).to eq(:normal)
    end

    it "should default respond with internal_fallback" do
      allow(subject).to receive(:run_strategy_selection).and_return([])
      allow(subject).to receive(:internal_fallback).and_return([1])
      subject.get_subject_ids
      expect(subject.selection_state).to eq(:internal_fallback)
    end

    it "should default respond with failover_fallback" do
      allow(subject).to receive(:run_strategy_selection).and_return([])
      allow(subject).to receive(:internal_fallback).and_return([])
      subject.get_subject_ids
      expect(subject.selection_state).to eq(:failover_fallback)
    end
  end
end
