module Serialization
  module HasManyFiltering
    class Options < RestPack::Serializer::Options
      def filters
        has_many_scope_filters
      end

      def filters_as_url_params
        has_many_scope_filters.sort.map { |k,v| map_filter_ids(k,v) }.join('&')
      end

      private

      def has_many_scope_filters
        @filters.merge(context.fetch(:has_many_filters, []))
      end
    end
  end
end
