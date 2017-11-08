require 'spec_helper'

describe CsvDumps::ProjectEmailList do
  let(:project) { create(:project) }
  let!(:email_pref)      { create(:user_project_preference, email_communication: true,  project: project) }
  let!(:non_email_pref)  { create(:user_project_preference, email_communication: false, project: project) }
  let!(:other_proj_pref) { create(:user_project_preference, email_communication: true,  project: create(:project)) }

  let(:users) { [ email_pref.user ] }

  it 'returns only emailable users' do
    list = described_class.new(project.id)
    expect { |b| list.each(&b) }.to yield_successive_args(*users)
  end
end
