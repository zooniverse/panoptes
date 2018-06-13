require "spec_helper"
require 'subjects/cellect_session'

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
    context "removing completes is disabled" do
      it "the complete remover is not called" do
        expect(Subjects::CompleteRemover).to_not receive(:new)
      end
    end

    context "removing completes is enabled" do
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
            expect(result).not_to include(sms.subject_id)
          end

          context "when the sms is retired for a different workflow" do
            let(:retired_workflow) do
              create(:workflow, subject_sets: workflow.subject_sets)
            end

            it 'should return all the subjects' do
              expect(result).to include(sms.subject_id)
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
