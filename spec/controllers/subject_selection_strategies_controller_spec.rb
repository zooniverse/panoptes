require 'spec_helper'

describe SubjectSelectionStrategiesController, type: :controller do
  def create_workflow_sws_records(workflow)
    workflow.subjects.each do |subject|
      SubjectWorkflowStatus.create!(
        subject_id: subject.id,
        workflow_id: workflow.id
      )
    end
  end

  let(:cellect_workflow) do
    create(:workflow_with_subjects, subject_selection_strategy: "cellect")
  end
  let(:non_cellect_workflow) { create(:workflow_with_subjects) }

  describe "GET 'workflows'" do
    let(:run_get) { get 'workflows', strategy: 'cellect', format: :json }

    context "as json" do
      before(:each) do
        cellect_workflow
        non_cellect_workflow
        [ cellect_workflow, non_cellect_workflow ].each do |workflow|
          create_workflow_sws_records(workflow)
        end
      end

      it "returns success" do
        run_get
        expect(response).to be_success
      end

      it "returns the expected json header" do
        run_get
        expect(response.content_type).to eq("application/json")
      end

      it "returns a public cache header" do
        Panoptes.flipper[:cellect_controller_caching].enable
        run_get
        cache_control = response.headers["Cache-Control"]
        expect(cache_control).to eq("max-age=600, public")
      end

      it "should respond with only the cellect workflow" do
        run_get
        expected = [cellect_workflow.slice(:id, :pairwise, :grouped, :prioritized)].as_json
        expect(json_response['workflows']).to eql(expected)
      end
    end
  end

  describe "GET 'subjects'" do
    let(:cellect_workflow) do
      create(:workflow_with_subjects, subject_selection_strategy: "cellect")
    end
    let(:another_cellect_workflow) do
      create(:workflow_with_subjects, subject_selection_strategy: "cellect")
    end
    let(:run_get) do
      get 'subjects', strategy: 'cellect', workflow_id: cellect_workflow.id.to_s, format: :json
    end

    context "as json" do
      let(:subjects) do
        cellect_workflow.set_member_subjects.map do |s|
          {
            'id' => s.subject_id,
            'priority' => s.priority,
            'subject_set_id' => s.subject_set_id
          }
        end
      end

      before do
        cellect_workflow
        another_cellect_workflow
        [ cellect_workflow, another_cellect_workflow ].each do |workflow|
          create_workflow_sws_records(workflow)
        end
      end

      it "returns a public cache header" do
        Panoptes.flipper[:cellect_controller_caching].enable
        run_get
        cache_control = response.headers["Cache-Control"]
        expect(cache_control).to eq("max-age=60, public")
      end

      it "should respond with only the subjects of the params workflow" do
        expect(subjects.count > 0).to be_truthy
        run_get
        expect(json_response["subjects"]).to match_array(subjects)
      end

      context "with a retired subject" do
        let(:retired_subject) { cellect_workflow.subjects.all.sample }
        let!(:retired_swc) do
          SubjectWorkflowStatus.where(
            subject_id: retired_subject.id,
            workflow_id: cellect_workflow.id
          ).update_all(
            retired_at: DateTime.now
          )
        end

        it "should not respond with retired subjects" do
          non_retired_ids = subjects.map{ |s| s['id'] } - [retired_subject.id]
          run_get
          response_ids = json_response["subjects"].map{ |s| s['id'] }
          expect(response_ids).to match_array(non_retired_ids)
        end
      end
    end
  end
end
