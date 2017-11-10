require 'spec_helper'

describe EmailsProjectsExportWorker do
  let(:worker) { described_class.new }

  it { is_expected.to be_a Sidekiq::Worker }

  it "should ignore any unknown project" do
    expect{ worker.perform(-1) }.not_to raise_error
  end

  it_behaves_like "an email dump exporter" do
    let(:project) { create(:project) }
    let!(:email_pref) do
      create(:user_project_preference, project: project)
    end
    let!(:non_email_pref) do
      create(:user_project_preference, email_communication: false, project: project)
    end
    let(:users) { [ email_pref.user ] }
    let(:scope_class) { CsvDumps::ProjectEmailList }
    let(:export_params) { project.id }
  end
end
