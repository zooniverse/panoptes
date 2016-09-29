require 'spec_helper'

describe UserProjectPreferences::FindOrCreateUponClassification do
  let(:user) { create :user }
  let(:project) { create :project }
  let(:operation) { described_class.with(user: user, project: project) }

  context 'when UPP already exists' do
    it 'returns the UPP' do
      user_project_preference = create :user_project_preference, user: user, project: project
      result = operation.run
      expect(result.result).to eq(user_project_preference)
    end
  end

  context 'when UPP does not exist' do
    it 'creates a UPP record' do
      result = operation.run
      expect(result).to be_valid
      expect(UserProjectPreference.count).to eq(1)
    end

    it 'triggers a classifiers count' do
      expect(ProjectClassifiersCountWorker).to receive(:perform_async).with(project.id)
      operation.run
    end

    it 'sets the user project_id if not set' do
      operation.run
      expect(user.reload.project_id).to eq(project.id)
    end

    it 'does not change the project_id if the user has one' do
      other_project = create :project
      user.update! project_id: other_project.id
      expect { operation.run }.not_to change { user.reload.project_id }
    end
  end
end
