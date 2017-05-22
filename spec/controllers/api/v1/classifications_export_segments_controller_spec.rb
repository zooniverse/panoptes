require "spec_helper"

describe Api::V1::ClassificationsExportSegmentsController, type: :controller do
  let(:project) { create(:project) }
  let!(:export_segments) do
    [
      create(:classifications_export_segment, project: project)
    ]
  end

  let(:scopes) { %w(public project) }
  let(:api_resource_name) { "classifications_export_segments" }
  let(:api_resource_attributes) { %w(started_at finished_at) }
  let(:api_resource_links) { %w(classifications_export_segments.project classifications_export_segments.workflow classifications_export_segments.requester) }
  let(:authorized_user) { project.owner }
  let(:resource) { export_segments.first }
  let(:resource_class) { ClassificationsExportSegment }

  describe "#index" do
    let(:index_params) { {project_id: project.id} }
    let(:n_visible) { 1 }

    it_behaves_like "is indexable", false

    it 'should not allow access to projects the user is not a collaborator on' do
      project2 = create :project
      segmnet2 = create :classifications_export_segment, project: project
      get :index, project_id: project2.id
      expect(response.status).to eq(401)
    end

    describe "filter options" do
      let(:filter_opts) { {} }
      let(:headers) { {} }
      before(:each) do
        index_params.merge!(filter_opts)
        default_request scopes: scopes, user_id: authorized_user.id
        request.env.merge!(headers)
        get :index, index_params
      end

      describe "filter by workflow" do
        let(:workflow2) { create :workflow, project: project }
        let(:export_segment2) { create :classifications_export_segment, project: project, workflow: workflow2}
        let(:filter_opts) { {workflow_id: export_segment2.workflow_id} }

        it 'should return matching pages' do
          expect(json_response[api_resource_name].map { |export_segment| export_segment['links']['workflow'] }).to all( eq(workflow2.id.to_s) )
        end
      end
    end

    describe "paging" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        get :index, index_params
      end

      it 'should use correct paging links' do
        expect(json_response["meta"][api_resource_name]["first_href"]).to match(%r{projects/[0-9]+/classifications_export_segments})
      end
    end
  end

  # describe "#show" do
  #   it_behaves_like "is showable"
  # end

  # describe "#create" do
  #   let(:test_attr) { :language }
  #   let(:lang) { "en-au" }
  #   let(:test_attr_value)  { lang }
  #   let(:create_params) do
  #     {
  #       field_guides: {
  #         items: [
  #           {icon: "789", title: "Stuff", content: 'things'},
  #           {icon: "897", title: "More things", content: 'other stuff'}
  #         ],
  #         language: lang,
  #         links: {
  #           project: project.id.to_s
  #         }
  #       }
  #     }
  #   end

  #   it_behaves_like "is creatable"
  # end

  # describe "#update" do
  #   let(:test_attr) { :items }
  #   let(:test_attr_value) do
  #     [{"icon" => "789", "title" => "Stuff", "content" => 'things'}]
  #   end

  #   let(:update_params) do
  #     {
  #       field_guides: {
  #         items: test_attr_value
  #       }
  #     }
  #   end

  #   it_behaves_like "is updatable"
  # end

  # describe "#destroy" do
  #   it_behaves_like "is destructable"
  # end
end
