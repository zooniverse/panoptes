# frozen_string_literal: true

require "spec_helper"

describe Api::V1::InaturalistController, type: :controller do
  describe "import" do
    let(:project) { create(:project) }
    let(:subject_set) { create :subject_set, project: project }
    let(:authorized_user) { project.owner }
    let(:unauthorized_user) { create(:user) }
    let(:import_params) { { taxon_id: 12345, subject_set_id: subject_set.id } }

    context 'a project owner' do
      before { default_request user_id: authorized_user.id }

      it 'enqueues a worker' do
        expect { post :import, import_params }
          .to change(InatImportWorker.jobs, :size).by(1)
      end

      it 'returns a successful status code' do
        response = post :import, import_params
        expect(response).to have_http_status(200)
      end

      it 'returns an error if the subject set is missing' do
        import_params[:subject_set_id] = 99999
        response = post :import, import_params
        expect(response).to have_http_status(404)
      end
    end

    context 'an unauthorized user' do
      before { default_request user_id: unauthorized_user.id }

      it 'fails if the user is unauthorized' do
        expect { post :import, import_params }.to not_change(InatImportWorker.jobs, :size)
      end

      it 'raises an error' do
        response = post :import, import_params
        expect(response).to have_http_status(403)
      end
    end
  end
end
