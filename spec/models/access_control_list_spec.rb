require 'spec_helper'

RSpec.describe AccessControlList, :type => :model do
  # pending "add some examples to (or delete) #{__FILE__}"

  let(:project) { create(:project) }
  let(:acl) { create(:access_control_list, resource: project) }

  describe "callbacks" do
    after(:each) { acl.update_attribute(:roles, ["expert"]) }
    it 'calls the method' do
      expect(acl).to receive(:send_collaborator_email)
    end

    it "calls the worker" do
      expect(UserInfoChangedMailerWorker).to receive :perform_async
    end
  end

  describe "#check_new_roles" do
    it "returns the right values" do
      acl.roles = ['expert']
      expect(acl.check_new_roles).to eq(['expert'])
    end
  end
end
