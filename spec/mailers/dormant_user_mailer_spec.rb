require "spec_helper"

RSpec.describe DormantUserMailer, :type => :mailer do
  let(:user) { create(:user) }
  let(:mail) { DormantUserMailer.email_dormant_user(user)}

  describe "dormant_user_email" do

    it 'should mail the user' do
      expect(mail.to).to include(user.email)
    end

    it 'should come from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("We still need your help on the Zooniverse")
    end

    it 'should have the user name in the body' do
      expect(mail.body.encoded).to match(user.display_name)
    end

    it 'should contain a custom user unsubscribe notice' do
      unsubscribe_url = unsubscribe_url(token: user.unsubscribe_token)
      expect(mail.body).to include(unsubscribe_url)
    end

    it 'should contain google analytic campaign codes' do
      expect(mail.body).to include("?utm_source=Newsletter&utm_campaign=")
    end

    it 'should contain a generic unsubscribe notice' do
      generic_unsubscribe = "Alternatively visit https://zooniverse.org/unsubscribe"
      expect(mail.body).to include(generic_unsubscribe)
    end

    it 'should contain a notice on how to manage your subscription prefs' do
      manage_subs = "To manage your email subscription preferences visit https://zooniverse.org/settings"
      expect(mail.body).to include(manage_subs)
    end

    it 'should contain google analytic campaign codes' do
      expect(mail.body).to include("?utm_source=Newsletter&utm_campaign=")
    end

    context "when the user has not classified before" do

      it 'should give a link to the main projects page' do
        expect(mail.body).to include("Check out the complete suite of projects here: https://zooniverse.org/projects")
      end

      it 'should be a general call to help' do
        expect(mail.body).to include("Our projects still need you!")
      end

    end

    context "when user has user project preference" do
      let(:user_project_preference) do
        create(:user_project_preference, project: project, user: user)
      end
      let(:last_project) { user_project_preference.project }

      before do
        last_project
      end

      context "when the users upp is their last project" do
        let(:project) { create(:project, owner: user) }

        it 'should have the name of the users last classified project in the body' do
          expect(mail.body).to include(last_project.display_name)
        end

        it 'should have the url for the users last classified project in the body' do
          expect(mail.body).to include("https://www.zooniverse.org/projects/#{last_project.slug}")
        end
      end

      context 'when the users last project is not launch approved' do
        let(:project) { create(:project, launch_approved: false, owner: user) }

        it 'should not have the last project url in the body' do
          expect(mail.body).not_to include("https://www.zooniverse.org/projects/#{last_project.slug}")
        end
      end

      context 'when the users last project is completed' do
        let(:project) { create(:project, completeness: 1.0, owner: user) }

        it 'should thank the user for their contributions to the project' do
          expect(mail.body).to include("Thank you for your help on #{last_project.display_name}")
        end

        it 'should have the url for project result page in the body' do
          expect(mail.body).to include("https://www.zooniverse.org/projects/#{last_project.slug}/about/results")
        end
      end
    end
  end
end
