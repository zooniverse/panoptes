module JsonApiRoutes
  def create_links(path, links)
    links_regex = /(#{ links.map(&:to_s).join('|') })/
    post "/links/:link_relation", to: "#{ path }#update_links",
      constraints: { link_relation: links_regex }, format: :false
    
    delete "/links/:link_relation/:link_ids", to: "#{ path }#update_links",
      constraints: { link_relation: links_regex }, format: :false
  end
  
  def json_api_resources(path, options={})
    links = options.delete(:links)
    options = options.merge(except: [:new, :edit],
                            format: false)
    resources(path, options) do
      create_links(path, links) if links
      yield if block_given?
    end
  end
end
