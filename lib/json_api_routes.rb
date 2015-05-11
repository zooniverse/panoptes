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

    delete "/links/:link_relation/:link_ids", to: "#{ path }#destroy_links",
           constraints: constraints, format: :false
  end

  def create_versions(path)
    get "/versions", to: "#{ path }#versions", format: false,
        constraints: id_constraint(path)
    get "/versions/:id", to: "#{ path }#version", format: false,
        constraints: id_constraint(path)
  end

  def create_head(path)
    match path, to: "#{path}#index", via: :head, format: false
    match "#{path}/:id", to: "#{path}#show", via: :head, format: false
  end

  def media_resources(*names)
    opts = names.last.is_a?(Hash) ? names.last : {}
    opts[:constraints] = {media_name: /(#{ names.map(&:to_s).join('|') })/ }
    opts[:except] = [:new, :edit]
    # Create links for has_one media relations
    get "/:media_name", to: "media#index", **opts
    post "/:media_name", to: "media#create", **opts
    # Create links for has_many media relations
    names = names.select{ |n| n.to_s == n.to_s.pluralize }
    opts[:constraints] = {media_name: /(#{ names.map(&:to_s).join('|') })/ }
    get "/:media_name/:id", to: "media#show", **opts
    put "/:media_name/:id", to: "media#update", **opts
    delete "/:media_name/:id", to: "media#destroy", **opts
  end

  def json_api_resources(path, options={})
    links = options.delete(:links)
    versioned = options.delete(:versioned)

    options = options.merge(except: [:new, :edit],
                            constraints: { id: VALID_IDS },
                            format: false)
    create_head(path)
    resources(path, options) do
      create_links(path, links) if links
      create_versions(path) if versioned
      yield if block_given?
    end
  end
end
