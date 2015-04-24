module RecentLinkSerializer
  extend ActiveSupport::Concern

  module ClassMethods
    def links
      links = super
      links["#{key}.recents"] = { href: "/#{recents_base_url}/{#{key}.id}/recents", type: "recents" }
      links
    end

    def recents_base_url
      key
    end
  end
end
