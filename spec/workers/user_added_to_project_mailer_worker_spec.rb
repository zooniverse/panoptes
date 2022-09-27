require 'spec_helper'

RSpec.describe UserAddedToProjectMailerWorker do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:roles) { ["collaborator"] }

  it 'should deliver the mail' do
    expect{ subject.perform(user.id, project.id, roles) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context "missing attributes" do
    it "is missing a user and doesn't send" do
      expect{ subject.perform(nil, project.id, roles) }.to_not change{ ActionMailer::Base.deliveries.count }
    end

    it "is missing a project and doesn't send" do
      expect{ subject.perform(user.id, nil, roles) }.to_not change{ ActionMailer::Base.deliveries.count }
    end

    it "is missing roles and doesn't send" do
      expect{ subject.perform(user.id, project.id, nil) }.to_not change{ ActionMailer::Base.deliveries.count }
    end
  end

  context "when an the user has been scrubbed of email address" do
    it 'should not deliver the mail' do
      UserInfoScrubber.scrub_personal_info!(user)
      expect{ subject.perform(user.id, project.id, roles) }.to_not change{ ActionMailer::Base.deliveries.count }
    end
  end

  context "when the user has an invalid email" do
    [ Net::SMTPSyntaxError, Net::SMTPFatalError ].each do |error_klass|
      before(:each) do
        allow_any_instance_of(ActionMailer::MessageDelivery)
          .to receive(:deliver)
          .and_raise(error_klass.new)
        allow(user).to receive(:email).and_return("test@example.com,ox")
      end

      it 'should attempt to send an email' do
        expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver)
        subject.perform(user.id, project.id, roles)
      end

      it 'should mark the user with invalid_email' do
        subject.perform(user.id, project.id, roles)
        expect(user.reload.valid_email).to eq(false)
      end
    end
  end
end
