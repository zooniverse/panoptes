module MediaLinksSerializer
  extend ActiveSupport::Concern

  module ClassMethods
    def media_include(*links)
      @can_includes ||= []
      @can_includes += links
      @media_links = links
    end

    def links
      links = super
      @media_links.each do |link|
        links.delete("#{key}.#{link}s")
        links["#{key}.#{link}"] = {
                                   href: media_link_href(link),
                                   type: "media"
                                  }
      end
      links
    end

    def media_link_href(link)
      "/#{media_base_url}/{#{key}.id}/#{link}"
    end

    def media_base_url
      key
    end

    def supported_association?(association_macro)
      super || :has_one == association_macro
    end
  end
end
