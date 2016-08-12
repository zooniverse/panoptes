require 'spec_helper'

describe CellectController, type: :controller do
  let(:cellect_workflow) do
    create(:workflow_with_subjects, use_cellect: true)
  end
  let(:non_cellect_workflow) { create(:workflow_with_subjects) }

  describe "GET 'workflows'" do
    let(:run_get) { get 'workflows', format: :json }

    context "as json" do
      before(:each) do
        cellect_workflow
        non_cellect_workflow
      end

      it "returns success" do
        run_get
        expect(response).to be_success
      end

      it "returns the expected json header" do
        run_get
        expect(response.content_type).to eq("application/json")
      end

      it "should respond with only the cellect workflow" do
        run_get
        expected = [cellect_workflow.slice(:id, :pairwise, :grouped, :prioritized)].as_json
        expect(json_response['workflows']).to eql(expected)
      end

      context "with a workflow that satifies the cellect subjects critera" do
        before do
          allow_any_instance_of(Workflow)
            .to receive(:cellect_size_subject_space?)
            .and_return(true)
        end

        it "should respond with all the workflows" do
          run_get
          workflows = Workflow.all.map{ |w| w.slice(:id, :pairwise, :grouped, :prioritized) }
          expected = { workflows: workflows }.as_json
          expect(json_response).to eq(expected)
        end
      end
    end
  end

  describe "GET 'subjects'" do
    let(:cellect_workflow) do
      create(:workflow_with_subjects, use_cellect: true)
    end
    let(:another_cellect_workflow) do
      create(:workflow_with_subjects, use_cellect: true)
    end
    let(:run_get) do
      get 'subjects', workflow_id: cellect_workflow.id.to_s, format: :json
    end

    context "as json" do
      let(:subjects) { cellect_workflow.set_member_subjects.map{ |s| s.slice(:id, :priority) } }

      before do
        cellect_workflow
        another_cellect_workflow
      end

      it "should respond with only the subjects of the params workflow" do
        expect(subjects.count > 0).to be_truthy
        run_get
        expect(json_response["subjects"]).to match_array(subjects)
      end

      context "with a retired subject" do
        let(:retired_subject) { subjects.sample }
        let!(:retired_swc) do
          create(:subject_workflow_count,
            subject_id: retired_subject['id'],
            workflow_id: cellect_workflow.id,
            retired_at: DateTime.now
          )
        end

        it "should not respond with retired subjects" do
          non_retired_ids = subjects.map{ |s| s['id'] } - [retired_subject['id']]
          run_get
          response_ids = json_response["subjects"].map{ |s| s['id'] }
          expect(response_ids).to match_array(non_retired_ids)
        end
      end

      context "when the worklfow is not set to use cellect" do
        let(:cellect_workflow) { create(:workflow_with_subjects) }

        it "should respond with an empty array" do
          run_get
          expect(json_response).to eq({ subjects: [] }.as_json)
        end
      end
    end
  end
end
