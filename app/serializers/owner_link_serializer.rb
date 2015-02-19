module OwnerLinkSerializer
  extend ActiveSupport::Concern

  module ClassMethods

    def links
      links = super
      links.delete("#{key}.owners")
      links["#{key}.owner"] = { href: "/{#{key}.owner.href}/{#{key}.owner.id}",
                                type: "owners" }
      links
    end
  end

  def add_links(model, data)
    data = super
    data[:links][:owner] = {id: @model.owner.id.to_s,
                            type: @model.owner.class.model_name.plural,
                            href: "#{@model.owner.class.model_name.route_key}/#{@model.owner.id}"}
    data
  end
end
