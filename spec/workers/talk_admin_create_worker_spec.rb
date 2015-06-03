require 'spec_helper'

RSpec.describe TalkAdminCreateWorker do
  subject { described_class.new }
  let(:project_id) { create(:project).id }

  describe "#perform" do
    it 'should call create_talk_admin for the requested project' do
      project = double
      client = double
      expect(subject).to receive(:client).and_return(client)
      expect(Project).to receive(:find).with(project_id).and_return(project)
      expect(project).to receive(:create_talk_admin).with(client)
      subject.perform(project_id)
    end
  end
end
