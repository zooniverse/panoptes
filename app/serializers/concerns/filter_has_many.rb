module FilterHasMany
  extend ActiveSupport::Concern

  module ClassMethods
    def page(params = {}, scope = nil, context = {})
      filters = has_many_filterable_by.map do |filter|
        filter << params.delete(filter[1])
      end.delete_if do |filter|
        filter[2].nil?
      end

      scope = filters.reduce(scope || self.model_class.all) do |query, filter|
        query.joins(filter[0]).where(filter[0] => {id: filter[2]})
      end

      super params, scope, context
    end

    def has_many_filterable_by
      filters = self.model_class.reflect_on_all_associations(:has_many)
        .map{ |r| reflection_to_filter(r) }
      filters += self.model_class.reflect_on_all_associations(:has_and_belongs_to_many)
        .map{ |r| reflection_to_filter(r) }
      filters.uniq
    end

    def reflection_to_filter(reflection)
      [reflection.name, :"#{reflection.name.to_s.singularize}_id"]
    end
  end
end
