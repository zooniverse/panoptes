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
    let(:test_attr_value) { source_url }
    let(:data_row_count) { 2 }
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
    let(:operation_double) do
      SubjectSetImports::CountManifestRows.with(api_user: ApiUser.new(nil), source_url: source_url)
    end

    before do
      allow(SubjectSetImports::CountManifestRows).to receive(:with).and_return(operation_double)
    end

    context 'when the manifest is not downloadable' do
      let(:error_message) { "Failed to download manifest: #{source_url}" }

      before do
        allow(operation_double).to receive(:run!).and_raise(SubjectSetImports::CountManifestRows::ManifestError, error_message)
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'returns a useful error message' do
        post :create, params: create_params
        returned_error_message = json_error_message(error_message)
        expect(response.body).to eq(returned_error_message)
      end
    end

    context 'when the manifest is under the limit' do
      before do
        allow(operation_double).to receive(:run!).and_return(data_row_count)
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it_behaves_like 'is creatable'

      it 'enqueues a worker' do
        expect { post :create, params: create_params }
          .to change(SubjectSetImportWorker.jobs, :size).by(1)
      end

      it 'sets the manifest_count attribute' do
        post :create, params: create_params
        import = SubjectSetImport.find(created_instance_id('subject_set_imports'))
        expect(import.manifest_count).to eq(data_row_count)
      end
    end

    context 'when the manifest is over the limit' do
      let(:error_message) { 'Manifest row count (2) exceeds the limit (1) and can not be imported' }
      let(:operation_error) { SubjectSetImports::CountManifestRows::LimitExceeded.new(error_message) }

      before do
        allow(operation_double).to receive(:run!).and_raise(operation_error)
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'returns a forbidden status code when the manifest is over the limit' do
        post :create, params: create_params
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns a useful error message when the manifest is over the limit' do
        post :create, params: create_params
        returned_error_message = json_error_message(error_message)
        expect(response.body).to eq(returned_error_message)
      end
    end
  end
end
