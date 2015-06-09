require 'spec_helper'

describe Api::EventsController, type: :controller do

  def overridden_params(new_params)
    event_params[:events].merge!(new_params)
    event_params
  end

  context "using json" do
    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/json"
      request.env["CONTENT_TYPE"] = "application/json"
    end

    describe "#create" do
      let(:workflow) { create(:workflow) }
      let(:project) { workflow.project }
      let(:user) { project.owner }
      let(:event_count) { 10 }
      let(:created_at) { project.created_at.to_s }
      let(:event_kind) { "workflow_activity" }
      let(:event_params) do
        {
          events: {
            kind: event_kind, project_id: project.id, project: project.name,
            zooniverse_user_id: user.id, workflow: workflow.display_name,
            count: event_count, created_at: created_at
          }
        }
      end
      let(:user_project_pref) do
        UserProjectPreference.where(project_id: project.id, user_id: user.id).first
      end
      let(:basic_auth) do
        creds = [ Panoptes::EventsApi.username,Panoptes::EventsApi.password ]
        ActionController::HttpAuthentication::Basic.encode_credentials(*creds)
      end

      before(:each) do
        request.env['HTTP_AUTHORIZATION'] = basic_auth
      end

      describe "basic auth method" do

        context "with valid authentication credentials" do

          it "should be successful" do
            post :create, event_params
            expect(response.status).to eq(200)
          end
        end

        context "with invalid authentication credentials" do
          let!(:basic_auth) do
            creds = [ user.login, user.password ]
            ActionController::HttpAuthentication::Basic.encode_credentials(*creds)
          end

          it "should return unauthorized" do
            post :create, event_params
            expect(response.status).to eq(401)
          end
        end
      end

      context "with an unknown project id" do
        let(:unexpected_event) do
          overridden_params(project_id: "")
        end

        it "should return 422" do
          post :create, unexpected_event
          expect(response.status).to eq(422)
        end
      end

      context "with an unknown user id" do
        let(:unexpected_event) do
          overridden_params(zooniverse_user_id: "")
        end

        it "should return 422" do
          post :create, unexpected_event
          expect(response.status).to eq(422)
        end
      end

      context "when an unexpected event kind message is received" do
        let(:unexpected_event) do
          overridden_params(kind: "unkonwn")
        end

        it "should notify honeybadger" do
          expect(Honeybadger).to receive(:notify)
          post :create, unexpected_event
        end

        it "should return 422" do
          post :create, unexpected_event
          expect(response.status).to eq(422)
        end
      end

      context "with a message with invalid params" do
        let(:invalid_event_params) do
          overridden_params(extra_param: "amazing")
        end

        it "should respond with a 422" do
          post :create, invalid_event_params
          expect(response.status).to eq(422)
        end
      end

      context "with a first event message" do
        let(:first_visit_event_params) do
          overridden_params(message: "first_visit")
        end

        it "should respond with a 200" do
          post :create, first_visit_event_params
          expect(response.status).to eq(200)
        end

        it "should create the user project preference model (upp)" do
          expect do
            post :create, first_visit_event_params
          end.to change { UserProjectPreference.count }.from(0).to(1)
        end

        it "should update the upp activity_count to the correct value" do
          post :create, first_visit_event_params
          expect(user_project_pref.activity_count).to eq(event_count)
        end
      end

      context "with an activity event message" do

        it "should respond with a 200" do
          post :create, event_params
          expect(response.status).to eq(200)
        end

        it "should create the user project preference model (upp)" do
          expect do
            post :create, event_params
          end.to change { UserProjectPreference.count }.from(0).to(1)
        end

        it "should update the upp activity_count to the correct value" do
          post :create, event_params
          expect(user_project_pref.activity_count).to eq(event_count)
        end

        context "when the user project preference already exists" do
          let!(:upp) do
            create(:user_project_preference, project: project, user: user, activity_count: 100)
          end

          it "should update the model only" do
            expect do
              post :create, event_params
            end.to_not change { UserProjectPreference.count }.from(1)
          end

          it "should overwrite the upp activity_count to the correct value" do
            post :create, event_params
            expect(upp.reload.activity_count).to eq(event_count)
          end
        end
      end
    end
  end
end
