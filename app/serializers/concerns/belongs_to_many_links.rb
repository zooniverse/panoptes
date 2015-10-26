module BelongsToManyLinks
  extend ActiveSupport::Concern

  module ClassMethods
    def links
      links = super
      btm_associations.each do |association|
        name = association.klass.model_name.plural
        links.delete(nil)
        links["#{key}.#{association.name}"] = {
                                               href: "/#{name}/{#{key}.#{association.name}}",
                                               type: name
                                              }
      end

      links
    end

    def btm_associations
      associations.select{ |assoc| assoc.macro == :belongs_to_many }
    end

    def supported_association?(association_macro)
      super || :belongs_to_many == association_macro
    end
  end

  def add_links(model, data)
    data = super
    self.class.btm_associations.each do |association|
      data[:links] ||= {}
      links_value = model.send(association.foreign_key).try(:map, &:to_s) || []
      unless links_value.blank?
        data[:links][association.name.to_sym] = links_value
      end
    end
    data
  end
end
