require 'spec_helper'

describe Api::EventsController, type: :controller do

  def overridden_params(new_params)
    event_params[:event].merge!(new_params)
    event_params
  end

  context "using json" do
    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/json"
      request.env["CONTENT_TYPE"] = "application/json"
    end

    describe "#create" do
      let(:zoo_home_project_id) { (10..20).to_a.sample }
      let(:workflow) { create(:workflow) }
      let(:project) do
        p = workflow.project
        p.update_columns(migrated: true, configuration: { zoo_home_project_id: zoo_home_project_id })
        p
      end
      let(:user) do
        user = project.owner
        user.update_column(:zooniverse_id, 1)
        user
      end
      let(:event_count) { {workflow.display_name => 10} }
      let(:created_at) { project.created_at.to_s }
      let(:event_kind) { "workflow_activity" }
      let(:event_params) do
        {
          event: {
            kind: event_kind, project_id: zoo_home_project_id, project: project.name,
            zooniverse_user_id: user.zooniverse_id, workflow: workflow.display_name,
            count: event_count.values.first, created_at: created_at
          },
          format: :json
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

      context "with malformed message" do
        let!(:event_params) { { } }

        it "should return 422" do
          post :create, event_params
          expect(response.status).to eq(422)
        end
      end

      context "with an invalid json message" do

        it "should return 422" do
          allow(subject).to receive(:create_params)
            .and_raise(ActionDispatch::ParamsParser::ParseError.new('test', 'test'))
          post :create, event_params
          expect(response.status).to eq(422)
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

      context "when the project id refers to a non-legacy migrated project" do
        let(:unknown_legacy_project) do
          overridden_params(project_id: project.id)
        end

        it "should respond with a 422" do
          post :create, unknown_legacy_project
          expect(response.status).to eq(422)
        end
      end

      context "with a first event message" do
        let(:first_visit_event_params) do
          params = overridden_params(message: "first_visit")
          params[:event] = params[:event].except(:count)
          params
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

        it "should increment the project's classifiers count" do
          expect(Project).to receive(:increment_counter).with(:classifiers_count, project.id)
          post :create, first_visit_event_params
        end

        context "with an unknown user zooniverse_id" do

          it "should not create the user project preference model (upp)" do
            allow(User).to receive(:find_by).and_return(nil)
            expect do
              post :create, first_visit_event_params
            end.not_to change { UserProjectPreference.count }
          end
        end

        context "with an panoptes-formatted user zooniverse_id" do

          it "should return success" do
            allow(User).to receive(:find_by).and_return(user)
            params = overridden_params(message: "first_visit", zooniverse_user_id: "panoptes-1")
            params[:event] = params[:event].except(:count)
            post :create, params
            expect(response.status).to eq(200)
          end
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

        it "should update the upp legacy_count to the correct value" do
          post :create, event_params
          expect(user_project_pref.legacy_count).to eq(event_count)
        end

        context "with busted per workflow count" do

          it "should respond with a 422" do
            allow(User).to receive(:find_by).and_return(user)
            post :create, overridden_params(workflow: "", count: nil)
            expect(response.status).to eq(422)
          end
        end

        context "with an panoptes-formatted user zooniverse_id" do

          it "should return success" do
            allow(User).to receive(:find_by).and_return(user)
            post :create, overridden_params(zooniverse_user_id: "panoptes-1")
            expect(response.status).to eq(200)
          end
        end

        context "when the user project preference already exists" do
          let!(:upp) do
            create(:user_project_preference, project: project, user: user, legacy_count: {workflow.display_name => 100})
          end

          it "should update the model only" do
            expect do
              post :create, event_params
            end.to_not change { UserProjectPreference.count }.from(1)
          end

          it "should not increment the project's classifiers count" do
            expect(Project).to_not receive(:increment_counter)
            post :create, event_params
          end

          it "should overwrite the upp legacy_count to the correct value" do
            post :create, event_params
            expect(upp.reload.legacy_count).to eq(event_count)
          end
        end
      end
    end
  end
end