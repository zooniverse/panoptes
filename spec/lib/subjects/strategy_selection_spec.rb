require "spec_helper"

RSpec.describe Subjects::StrategySelection do
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:smses) { subject_set.set_member_subjects }
  let(:user) { workflow.project.owner }
  let(:limit) { described_class::DEFAULT_LIMIT }
  subject do
    described_class.new(workflow, user, subject_set.id, limit)
  end

  describe "#select" do
    it "should not call the complete remover when disabled" do
      Panoptes.flipper[:remove_complete_subjects].disable
      expect(Subjects::CompleteRemover).to_not receive(:new)
      subject.select
    end

    context "removing completes is enabled" do
      let(:complete_remover) do
        instance_double(
          Subjects::CompleteRemover,
          incomplete_ids: [1]
        )
      end
      let(:selected_subject_ids) { [ 1, 3, 2] }

      before do
        allow(subject).to receive(:select_subject_ids).and_return(selected_subject_ids)
      end

      it "should call the complete remover after selection" do
        expect(complete_remover).to receive(:incomplete_ids)
        expect(Subjects::CompleteRemover)
          .to receive(:new)
          .with(user, workflow, selected_subject_ids)
          .and_return(complete_remover)
        subject.select
      end
    end

    context "when selecting subjects" do
      let(:result_ids) { [1] }

      context "with cellect" do
        let(:run_selection) { subject.select }

        before do
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
      end
    end
  end
end
