module JsonApiRoutes
  VALID_IDS = /[0-9]*/
  
  def id_constraint(path)
    { :"#{ path.to_s.singularize }_id" => VALID_IDS }
  end
  
  def create_links(path, links)
    links_regex = /(#{ links.map(&:to_s).join('|') })/
    constraints = { link_relation: links_regex }.merge(id_constraint(path))
    
    post "/links/:link_relation", to: "#{ path }#update_links",
      constraints: constraints, format: :false
    
    delete "/links/:link_relation/:link_ids", to: "#{ path }#update_links",
      constraints: constraints, format: :false
  end

  def create_versions(path)
    get "/versions", to: "@{ path }#versions", format: false
    get "/versions/:id", to: "#{ path }#version", format: false
  end
  
  def json_api_resources(path, options={})
    links = options.delete(:links)
    versioned = options.delete(:version)
    options = options.merge(except: [:new, :edit],
                            constraints: { id: VALID_IDS },
                            format: false)
    resources(path, options) do
      create_links(path, links) if links
      create_versions(path) if versioned
      yield if block_given?
    end
  end
end
