module MediaLinksSerializer
  extend ActiveSupport::Concern

  module ClassMethods
    def media_include(*links)
      @can_includes ||= []
      links.each do |link|
        case link
        when Symbol
          @can_includes << link
        when Hash
          opts = link.values
          link_names = link.keys
          link_names.each.with_index do |name, i|
            @can_includes << name if opts[i].fetch(:include, true)
          end
        end
      end
      @media_links = links.flat_map do |link|
        case link
        when Hash
          link.keys
        else
          link
        end
      end
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
      case id
      when String
        data[:links][link][:id] = id
      when Array
        data[:links][link][:ids] = id
      end
    end
    data
  end

  def media_href(model, link)
    "/#{self.class.key}/#{model.id}/#{link}"
  end
end
