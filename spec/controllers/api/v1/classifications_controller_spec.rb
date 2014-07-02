require 'spec_helper'

def send_create_request(workflow_id, set_member_subject_id)
  request.session = { cellect_hosts: { workflow_id.to_s => "example.com" } }
  params = { workflow_id: workflow.id,
             subject_id: set_member_subject_id,
             annotations: [] }
  post :create, params
end

describe Api::V1::ClassificationsController, type: :controller do
  let!(:workflow) { create(:workflow_with_subjects) }
  let!(:set_member_subject) { workflow.subject_sets.first.set_member_subjects.first }
  let!(:user) { create(:user) }

  context "logged in user" do
    before(:each) do
      stub_cellect_connection
      default_request user_id: user.id, scopes: ["classifications"]
    end

    describe "#create" do

      it "should return 204" do
        send_create_request(workflow.id, set_member_subject.id)
        expect(response.status).to eq(204)
      end

      it "should send the add seen command to cellect" do
        expect(stubbed_cellect_connection).to receive(:add_seen).with(
          set_member_subject.id.to_s,
          workflow_id: workflow.id.to_s,
          user_id: user.id,
          host: 'example.com'
        )
        send_create_request(workflow.id, set_member_subject.id)
      end
    end
  end
end
