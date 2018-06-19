require 'spec_helper'

RSpec.describe UserProjectPreferencesWorker do
  let(:project) { create(:project) }
  let(:user) { project.owner }

  it 'should call the operation' do
    expect(UserProjectPreferences::FindOrCreate)
      .to receive(:run!)
      .with(user: user, project: project)
    subject.perform(user.id, project.id)
  end
end
