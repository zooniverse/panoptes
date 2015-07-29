module SluggedName
  extend ActiveSupport::Concern

  included do
    acts_as_url :slugged_name, allow_slash: true, sync_url: true, url_attribute: :slug, allow_duplicates: true
  end

  def slugged_name
    "#{ owner.try(:login) || owner.try(:name) }/#{ display_name.try(:gsub, '/', '-') }"
  end
end
