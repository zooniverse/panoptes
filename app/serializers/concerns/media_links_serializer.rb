module MediaLinksSerializer
  extend ActiveSupport::Concern

  module ClassMethods
    def media_include(*links)
      @can_includes ||= []
      @can_includes += links
      @media_links = links
    end

    def media_links
      @media_links || []
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

  def add_links(model, data)
    data = super
    self.class.media_links.each do |link|
      id = data[:links].delete(link)
      data[:links][link] = {
                            href: media_href(model, link),
                            type: link.to_s.pluralize
                           }
      data[:links][link][:id] = id if id
    end
    data
  end

  def media_href(model, link)
    "/#{self.class.key}/#{model.id}/#{link}"
  end
end
