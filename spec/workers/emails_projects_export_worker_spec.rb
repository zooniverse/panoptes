require 'spec_helper'

describe EmailsProjectsExportWorker do
  let(:worker) { described_class.new }

  it { is_expected.to be_a Sidekiq::Worker }

  it "should ignore any unknown project" do
    expect{ worker.perform(-1) }.not_to raise_error
  end

  it_behaves_like "an email dump exporter", :focus do
    let(:project) { create(:project) }
    let!(:prefs) { create(:user_project_preference, project: project) }
    let(:s3_path) { "email_exports/#{project.slug}_email_list.tar.gz" }
    let(:s3_opts) do
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"#{project.slug}_email_list.csv\""
      }
    end
    let(:export_params) { project.id }
  end
end
