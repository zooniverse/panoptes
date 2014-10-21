class Api::V1::ProjectContentsController < Api::ApiController
  include JsonApiController

  doorkeeper_for :all, scopes: [:project]
  resource_actions :default

  def self.team_member_params
    [:name, :bio, :twitter, :institution]
  end

  def self.guide_params
    [:image, :explanation]
  end

  allowed_params :create, :language, :title, :description, :science_case,
    :introduction, team_members: team_member_params, guide: guide_params,
    links: [:project]

  allowed_params :update, :language, :title, :description, :science_case,
    :introduction, team_members: team_member_params, guide: guide_params
end
