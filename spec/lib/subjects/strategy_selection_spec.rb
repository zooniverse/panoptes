require "spec_helper"
require 'subjects/cellect_session'

RSpec.describe Subjects::StrategySelection do
  let(:strategy) { nil }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { workflow.project.owner }
  let(:limit) { SubjectQueue::DEFAULT_LENGTH }
  subject do
    described_class.new(workflow, user, subject_set.id, limit, strategy)
  end

  describe "#select" do

    describe "remove seens after selection" do
      let(:seen_remover) { instance_double("Subjects::SeenRemover") }
      let(:uss) { instance_double("UserSeenSubject") }

      before do
        allow(seen_remover).to receive(:unseen_ids).and_return([])
        allow(uss).to receive(:subject_ids).and_return([])
        allow(UserSeenSubject).to receive(:find_by).and_return(uss)
      end

      it "should call the seens remover after selection", :aggregate_failures do
        expect(subject).to receive(:strategy_sms_ids)
          .and_return([1,2,3]).ordered
        expect(Subjects::SeenRemover)
          .to receive(:new)
          .with(uss, an_instance_of(Array))
          .and_return(seen_remover).ordered
        subject.select
      end
    end

    context "when selecting via strategy param" do
      let(:result_ids) { [1] }

      it "should fallback from the override strategy" do
        expect_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select)
          .and_call_original
        subject.select
      end

      context "with cellect" do
        let(:strategy) { :cellect }
        let(:run_selection) { subject.select }
        before do
          allow(Panoptes).to receive(:cellect_on).and_return(true)
        end

        it "should use the cellect client" do
          expect(Subjects::CellectClient).to receive(:get_subjects)
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
          allow(Subjects::CellectClient).to receive(:get_subjects)
            .and_return(result_ids)
          expect(SetMemberSubject).to receive(:by_subject_workflow)
            .with(result_ids, workflow.id).and_call_original
          run_selection
        end

        context "when the cellect client can't reach a server" do
          it "should fall back to postgres strategy" do
            allow(Subjects::CellectClient).to receive(:get_subjects)
              .and_raise(Subjects::CellectClient::ConnectionError)
            expect_any_instance_of(Subjects::PostgresqlSelection)
              .to receive(:select)
            run_selection
          end
        end
      end
    end
  end

  describe "#strategy" do
    let(:config) { { selection_strategy: :cellect } }
    let(:cellect_size) { Panoptes.cellect_min_pool_size }

    before do
      allow(subject).to receive(:workflow).and_return(workflow)
    end

    it "should fall back to postgresql strategy when not set" do
      expect(subject.strategy).to eq(nil)
    end

    context "when Cellect config is on" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(true)
      end

      context "when providing cellect strategy param" do
        let(:strategy) { :cellect }

        it "should use the supplied strategy" do
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "when the workflow config has a selection strategy" do
        it "should use the workflow config strategy" do
          allow(workflow).to receive(:configuration).and_return(config)
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should use the cellect strategy" do
          allow(workflow).to receive_message_chain("set_member_subjects.count") do
            cellect_size
          end
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "with a workflow config and large subject set size" do
        it "should only use the worfklow strategy", :aggregate_failures do
          allow(workflow).to receive(:configuration).and_return(config)
          allow(workflow).to receive_message_chain("set_member_subjects.count") do
            cellect_size
          end
          expect(workflow).not_to receive(:set_member_subjects)
          expect(subject.strategy).to eq(:cellect)
        end
      end
    end

    context "when Cellect Config is off" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(false)
      end

      context "when providing cellect strategy param" do
        let(:strategy) { :cellect }

        it "should never use cellect" do
          expect(subject.strategy).to eq(nil)
        end
      end

      context "when the workflow config has a selection strategy" do
        it "should not ask the workflow" do
          expect(subject).not_to receive(:workflow_strategy)
          expect(subject.strategy).to eq(nil)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should not query workflow about cellect" do
          expect_any_instance_of(Workflow).not_to receive(:using_cellect?)
          expect(subject.strategy).to eq(nil)
        end
      end
    end
  end
end
