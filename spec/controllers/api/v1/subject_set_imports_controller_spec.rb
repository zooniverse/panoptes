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
    # The first import is linked to the project that we're the owner of, and should be visible
    # The second import is linked to a different public project, which we don't own, and should be invisible
    # The third import is linked to a different private project, which we also don't own, and should be invisible
    let(:n_visible) { 1 }
    let(:private_resource) { subject_set_imports.last }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe '#create' do
    let(:test_attr) { :source_url }
    let(:source_url) { 'https://example.org/file.csv' }
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

    before do
      allow(UrlDownloader).to receive(:stream).and_yield(true)
      csv_import_double = instance_double(SubjectSetImport::CsvImport, count: 2)
      allow(SubjectSetImport::CsvImport).to receive(:new).and_return(csv_import_double)
    end

    it_behaves_like 'is creatable'

    it 'enqueues a worker' do
      default_request scopes: scopes, user_id: authorized_user.id
      expect { post :create, create_params }
        .to change(SubjectSetImportWorker.jobs, :size).by(1)
    end

    it 'sets the manifest_count attribute' do
      default_request scopes: scopes, user_id: authorized_user.id
      post :create, create_params
      import = SubjectSetImport.find(created_instance_id('subject_set_imports'))
      expect(import.manifest_count).to eq(2)
    end

    context 'when the manifest is over the limit' do
      before do
        allow(ENV).to receive(:fetch).with('SUBJECT_SET_IMPORT_MANIFEST_ROW_LIMIT', 10000).and_return(1)
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'returns a fobidden status code when the manifest is over the limit' do
        post :create, create_params
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns a useful error message when the manifest is over the limit' do
        post :create, create_params
        error_message = json_error_message('Manifest row count (2) exceeds the limit (1) and can not be imported')
        expect(response.body).to eq(error_message)
      end

      it 'skips validation for admin uploads' do
        project.owner.update_column(:admin, true)
        post :create, create_params.merge(admin: true)
        expect(response).to have_http_status(:created)
      end
    end
  end
end
