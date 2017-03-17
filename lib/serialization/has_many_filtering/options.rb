module Serialization
  module HasManyFiltering
    class Options < RestPack::Serializer::Options
      attr_reader :has_many_filters

      def initialize(has_many_filters, serializer, params, scope, context)
        @has_many_filters = has_many_filters
        super(serializer, params, scope, context)
      end

      def filters
        has_many_scope_filters
      end

      def filters_as_url_params
        has_many_scope_filters.sort.map { |k,v| map_filter_ids(k,v) }.join('&')
      end

      private

      def has_many_scope_filters
        @has_many_scope_filters ||= @filters.merge(has_many_filters)
      end
    end
  end
end
