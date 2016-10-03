require 'spec_helper'

describe Projects::CreateSubjectsExport do
  let(:user) { create :user }
  let(:api_user) { ApiUser.new(user) }
  let(:operation) { described_class.with(api_user: api_user) }
  let(:resource) { create(:full_project, owner: user) }

  let(:export_worker) { SubjectsDumpWorker }
  let(:medium_type) { "project_subjects_export" }
  let(:content_type) { "text/csv" }

  it_behaves_like "creates an export"
end
