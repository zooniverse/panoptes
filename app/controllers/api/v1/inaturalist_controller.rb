# frozen_string_literal: true

class Api::V1::InaturalistController < Api::ApiController
  def import
    subject_set = SubjectSet.find(params[:subject_set_id])

    unless subject_set.project.owners_and_collaborators.include?(api_user.user)
      raise Api::Unauthorized, 'Must be owner or collaborator to import'
    end

    InatImportWorker.perform_async(api_user.id, params[:taxon_id], params[:subject_set_id], params[:updated_since])
    json_api_render(:ok, {})
  end
end
