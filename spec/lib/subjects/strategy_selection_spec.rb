require "spec_helper"
require 'subjects/cellect_session'

RSpec.describe Subjects::StrategySelection do
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:smses) { subject_set.set_member_subjects }
  let(:user) { workflow.project.owner }
  let(:limit) { SubjectQueue::DEFAULT_LENGTH }
  subject do
    described_class.new(workflow, user, subject_set.id, limit)
  end

  describe "#select" do
    context "removing completes is disabled" do
      it "the complete remover is not called" do
        expect(Subjects::CompleteRemover).to_not receive(:new)
      end
    end

    context "removing completes is enabled" do
      before { Panoptes.flipper[:remove_complete_subjects].enable }

      it "should call the complete remover after selection", :aggregate_failures do
        expect(subject).to receive(:select_sms_ids).and_return([:default, [1,2,3]]).ordered
        expect(Subjects::CompleteRemover)
          .to receive(:new)
          .with(user, workflow, an_instance_of(Array))
          .ordered
          .and_return(instance_double(Subjects::CompleteRemover, incomplete_ids: [1]))
        subject.select
      end

      describe "remove completed after selection" do
        let(:retired_workflow) { workflow }
        let(:sms) { smses[0] }
        let(:result) { subject.select }

        before do
          allow(subject).to receive(:select_sms_ids).and_return([:default, smses.map(&:id)])
        end

        context "retired subjects" do
          let!(:sws) do
            create(:subject_workflow_status,
              subject: sms.subject,
              workflow: retired_workflow,
              retired_at: Time.zone.now
            )
          end

          it 'should not return retired subjects' do
            expect(result).not_to include(sms.id)
          end

          context "when the sms is retired for a different workflow" do
            let(:retired_workflow) do
              create(:workflow, subject_sets: workflow.subject_sets)
            end

            it 'should return all the subjects' do
              expect(result).to include(sms.id)
            end
          end
        end

        context "seen subjects" do
          let!(:seens) do
            create(:user_seen_subject, user: user, workflow: workflow, subject_ids: [sms.subject.id])
          end

          it 'should not return seen subjects' do
            expect(result).not_to include(sms.id)
          end
        end
      end
    end

    context "when selecting subjects" do
      let(:result_ids) { [1] }

      it "should select using postgresql by default" do
        expect_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select)
          .and_call_original
        subject.select
      end

      context "with cellect" do
        let(:run_selection) { subject.select }
        before do
          allow(Panoptes.flipper).to receive(:enabled?).with("cellect").and_return(true)
          workflow.subject_selection_strategy = "cellect"
        end

        it "should use the cellect client" do
          cellect_params = [ workflow.id, user.id, subject_set.id, limit ]
          expect(CellectClient)
            .to receive(:get_subjects)
            .with(*cellect_params)
            .and_return(result_ids)
          run_selection
        end

        it "should use a cellect session instance for session tracking" do
          stub_cellect_connection
          stub_redis_connection
          expect(Subjects::CellectSession).to receive(:new).and_call_original
          run_selection
        end

        it "should convert the cellect subject_ids to panoptes sms_ids" do
          allow(CellectClient).to receive(:get_subjects)
            .and_return(result_ids)
          expect(SetMemberSubject).to receive(:by_subject_workflow)
            .with(result_ids, workflow.id).and_call_original
          run_selection
        end

        context "when the cellect client can't reach a server" do
          it "should fall back to postgres strategy" do
            allow(CellectClient).to receive(:get_subjects)
              .and_raise(CellectClient::ConnectionError)
            expect_any_instance_of(Subjects::PostgresqlSelection)
              .to receive(:select)
              .and_call_original
            run_selection
          end
        end
      end

      context "with designator" do
        let(:run_selection) { subject.select }

        before do
          workflow.subject_selection_strategy = "designator"
        end

        it "should use the designator client" do
          expect_any_instance_of(Subjects::DesignatorSelector)
            .to receive(:get_subjects)
            .with(user, subject_set.id, limit)
            .and_return(result_ids)
          run_selection
        end

        it "should convert the designator subject_ids to panoptes sms_ids" do
          allow_any_instance_of(DesignatorClient).to receive(:get_subjects)
            .and_return(result_ids)
          expect(SetMemberSubject).to receive(:by_subject_workflow)
            .with(result_ids, workflow.id).and_call_original
          run_selection
        end
      end
    end
  end

  describe "#strategy" do
    let(:cellect_size) { Panoptes.cellect_min_pool_size }

    before do
      allow(subject).to receive(:workflow).and_return(workflow)
    end

    it "should fall back to postgresql strategy when not set" do
      expect(subject.strategy).to eq(nil)
    end

    context "when Cellect config is on" do
      before do
        allow(Panoptes.flipper).to receive(:enabled?).with("cellect").and_return(true)
        allow(Panoptes.flipper).to receive(:enabled?).with("designator").and_return(true)
      end

      context "when the workflow is set to use cellect" do
        it "should use the workflow config strategy" do
          allow(workflow).to receive(:subject_selection_strategy).and_return("cellect")
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should use the cellect strategy" do
          allow(workflow).to receive(:subjects_count).and_return(cellect_size)
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "workflow is set to use cellect cellect and large subject set size" do
        it "should only use the workflow strategy", :aggregate_failures do
          allow(workflow).to receive(:subject_selection_strategy).and_return("cellect")
          allow(workflow)
            .to receive(:cellect_size_subject_space?)
            .and_return(true)
            .and_call_original
          expect(workflow).not_to receive(:set_member_subjects)
          expect(subject.strategy).to eq(:cellect)
        end
      end
    end

    context "when Cellect Config is off" do
      before do
        allow(Panoptes.flipper).to receive(:enabled?).with("cellect").and_return(false)
        allow(Panoptes.flipper).to receive(:enabled?).with("designator").and_return(false)
      end

      context "when the workflow config has a selection strategy" do
        it "should not ask the workflow" do
          expect(subject).not_to receive(:workflow_strategy)
          expect(subject.strategy).to eq(nil)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should not query workflow about cellect" do
          expect_any_instance_of(Workflow).not_to receive(:using_subject_selection_strategy)
          expect(subject.strategy).to eq(nil)
        end
      end
    end

    describe 'designator' do
      context "when the workflow is set to use designator" do
        it "should use the workflow config strategy" do
          allow(workflow).to receive(:subject_selection_strategy).and_return("designator")
          expect(subject.strategy).to eq(:designator)
        end
      end

      context 'when the workflow has a lot of subjects' do
        it 'should still use designator' do
          allow(workflow).to receive(:subject_selection_strategy).and_return("designator")
          allow(workflow).to receive(:subjects_count).and_return(cellect_size)
          expect(subject.strategy).to eq(:designator)
        end
      end
    end
  end
end
