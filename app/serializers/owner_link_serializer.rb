module OwnerLinkSerializer
  extend ActiveSupport::Concern

  module ClassMethods

    def links
      links = super
      links.delete("#{key}.owners")
      links["#{key}.owner"] = { href: "/{#{key}.owner.href}", type: "owners" }
      links
    end
  end

  def add_links(model, data)
    data = super
    model_name = @model.owner.class.model_name
    data[:links][:owner] = { id: @model.owner.id.to_s,
                             type: model_name.plural,
                             href: "/#{model_name.route_key}/#{@model.owner.id}" }
    data
  end
end
