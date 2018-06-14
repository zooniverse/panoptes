require "spec_helper"

describe Api::V1::SubjectSetImportsController, type: :controller do
  let(:private_project) { create(:project, private: true) }
  let(:project) { create(:project) }

  let(:subject_set) { create :subject_set, project: project }
  let(:private_subject_set) { create :subject_set, project: private_project }

  let!(:subject_set_imports) do
    [ create(:subject_set_import, subject_set: subject_set),
      create(:subject_set_import),
      create(:subject_set_import, subject_set: private_subject_set) ]
  end

  let(:scopes) { %w(public project) }
  let(:api_resource_name) { "subject_set_imports" }
  let(:api_resource_attributes) { %w(source_url) }
  let(:api_resource_links) { %w(subject_set_imports.subject_set) }
  let(:authorized_user) { project.owner }
  let(:resource) { subject_set_imports.first }
  let(:resource_class) { SubjectSetImport }

  describe "#index" do
    let(:n_visible) { 2 }
    let(:private_resource) { subject_set_imports.last }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe "#create" do
    let(:test_attr) { :source_url }
    let(:source_url) { "https://example.org/file.csv" }
    let(:test_attr_value)  { source_url }
    let(:create_params) do
      {
        subject_set_imports: {
          source_url: source_url,
          links: {
            subject_set: subject_set.id.to_s
          }
        }
      }
    end

    it_behaves_like "is creatable"

    it 'enqueues a worker' do
      default_request scopes: scopes, user_id: authorized_user.id
      expect { post :create, create_params }
        .to change(SubjectSetImportWorker.jobs, :size).by(1)
    end
  end
end
