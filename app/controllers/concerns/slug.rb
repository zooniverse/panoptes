module Slug
  extend ActiveSupport::Concern

  included do
    before_action :downcase_slug, only: :index
  end

  def downcase_slug
    if params.key? "slug"
      params[:slug] = params[:slug].downcase
    end
  end
end
