require 'spec_helper'

describe CellectController, type: :controller do
  let(:cellect_workflow) do
    create(:workflow, use_cellect: true)
  end
  let(:non_cellect_workflow) { create(:workflow) }

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
        expect(json_response).to eq({"workflow_ids"=>[cellect_workflow.id]})
      end

      context "with a workflow that satifies the cellect subjects critera" do
        before do
          allow_any_instance_of(Workflow)
            .to receive(:cellect_size_subject_space?)
            .and_return(true)
        end

        it "should respond with all the workflows" do
          run_get
          expect(json_response).to eq({"workflow_ids"=>Workflow.all.pluck(:id)})
        end
      end
    end
  end
end
