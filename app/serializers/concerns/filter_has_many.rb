module FilterHasMany
  extend ActiveSupport::Concern

  module ClassMethods
    def page(params = {}, scope = nil, context = {})
      filters = scope_filters_from_params(params)

      scope = filters.reduce(scope || self.model_class.all) do |query, filter|
        query.joins(filter[0]).where(filter[0] => {id: filter[2]})
      end

      # As our RestPack doesn't' handle the join filtering natively, we need to
      # use this custom options class to percolate the has_many filters
      # into the response meta paging urls and still use the has_many
      # join scopes built above.
      serializer_options = ::Serialization::HasManyFiltering::Options.new(
        has_many_filters(filters),
        self,
        params,
        paging_scope(params, scope, context),
        context
      )

      # Use the custom paging instance to create a paged response
      page_with_options serializer_options
    end

    def scope_filters_from_params(params)
      has_many_filterable_by.map do |filter|
        filter_ids = params.delete(filter[1])
        filter << filter_ids.to_s.split(",")
      end.delete_if do |filter|
        filter[2].blank?
      end
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

    def has_many_filters(scope_filters)
      filters_hash = scope_filters.map do |filter|
        [ filter[1], Array.wrap(filter[2]) ]
      end
      Hash[ filters_hash ]
    end
  end
end
