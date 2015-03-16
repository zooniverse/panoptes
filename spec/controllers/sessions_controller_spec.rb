require 'spec_helper'

describe SessionsController, type: :controller do
  let!(:users) { create_list(:user, 2, build_zoo_user: true) }
  let(:user) { users.first }

  context "using json", :zoo_home_user do
    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/json"
      request.env["CONTENT_TYPE"] = "application/json"
      request.env["devise.mapping"] = Devise.mappings[:user]
    end

    describe "#create" do
      it "should respond with the user object" do
        post :create, user: {display_name: user.display_name, password: user.password}
        expect(json_response).to include("users")
      end

      it "should respond with a 200" do
        post :create, user: {display_name: user.display_name, password: user.password}
        expect(response.status).to eq(200)
      end

      it "should sign in the user" do
        expect(controller).to receive(:sign_in)
        post :create, user: {display_name: user.display_name, password: user.password}
      end

      it "should test against the ZooniverseUser table" do
        expect(ZooniverseUser).to receive(:authenticate).with(user.display_name, user.password)
        post :create, user: {display_name: user.display_name, password: user.password}
      end

      context "when signing in a zooniverse wide user account" do
        let(:zoo_user) { create(:zooniverse_user) }

        it "should import the zooniverse user into the User table" do
          expect do
            post :create, user: {display_name: zoo_user.login, password: zoo_user.password}
          end.to change{User.count}.from(2).to(3)
        end

        context "when an existing panoptes user account exists" do
          let!(:dup_user) do
            create(:user, display_name: zoo_user.login, email: zoo_user.email)
          end

          it "should not raise an error" do
            expect do
              post :create, user: {display_name: zoo_user.login, password: zoo_user.password}
            end.to_not raise_error
          end

          it "should update the existing panoptes account with zoo home details" do
            panoptes_user = User.find_by(email: zoo_user.email)
            expect(panoptes_user.hash_func).to eq("bcrypt")
            post :create, user: { display_name: zoo_user.login,
                                  password: zoo_user.password }
            expect(panoptes_user.reload.hash_func).to eq("sha1")
          end
        end

        context "when an existing panoptes user account has been deleted" do
          let!(:disabled_dup_user) do
            user = create(:user, display_name: zoo_user.login, email: zoo_user.email)
            user.disable!
            user
          end

          it "should not raise an error" do
            expect do
              post :create, user: {display_name: zoo_user.login, password: zoo_user.password}
            end.to_not raise_error
          end

          it "should not sign the user in" do
            post :create, user: { display_name: zoo_user.login,
                                  password: zoo_user.password }
            expect(response.status).to eq(401)
          end
        end
      end
    end

    describe "#destroy" do
      context "a signed in user" do
        before(:each) do
          request.env['devise.user'] = user
          sign_in user
        end

        it 'should return no-content' do
          delete :destroy
          expect(response.status).to eq(204)
        end

        it 'should sign out the user' do
          expect(controller).to receive(:sign_out)
          delete :destroy
        end
      end
    end

    describe "#new" do
      let(:providers) { %w(facebook) }

      before(:each) do
        get :new
      end

      it 'should return 200' do
        expect(response.status).to eq(200)
      end

      it 'should return a json response of login routes' do
        expect(json_response).to include('login', *providers)
      end

      it 'should return the url for each omniauth provider' do
        expect(json_response['facebook']).to eq('/users/auth/facebook')
      end
    end
  end
end
