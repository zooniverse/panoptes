module Serialization
  module PanoptesRestpack
    extend ActiveSupport::Concern

    included do
      include RestPack::Serializer
      extend ClassMethodOverrides
    end

    module ClassMethods
      def preload(*preloads)
        @preloads ||= []
        @preloads += preloads
      end

      def preloads
        @preloads || []
      end

      def cache_total_count(cache_setting)
        @cache_total_count ||= !!cache_setting
      end

      def cache_total_count_on
        @cache_total_count || false
      end
    end

    module ClassMethodOverrides
      def page(params = {}, scope = nil, context = {})
        super(params, paging_scope(params, scope), context)
      end

      def paging_scope(params, scope)
        if params[:include]
          param_preloads = params[:include].split(',').map(&:to_sym) & self.can_includes
        end

        preload_relations = preloads | Array.wrap(param_preloads)
        unless preload_relations.empty?
          scope = scope.preload(*preload_relations)
        end

        scope
      end

      private

      def page_href(page, options)
        return nil unless page

        params = []
        params << "page=#{page}" unless page == 1
        params << "page_size=#{options.page_size}" unless options.default_page_size?
        params << "include=#{options.include.join(',')}" if options.include.any?
        params << options.sorting_as_url_params if options.sorting.any?
        params << options.filters_as_url_params if options.filters.any?

        url = page_url(options.context)
        url += '?' + params.join('&') if params.any?
        url
      end

      def page_url(context)
        case
        when context[:url_prefix]
          "#{href_prefix}/#{context[:url_prefix]}/#{key}"
        when context[:url_suffix]
          "#{href_prefix}/#{key}/#{context[:url_suffix]}"
        else
          "#{href_prefix}/#{key}"
        end
      end

      def serialize_meta(page, options)
        if cache_total_count_on
          page = Serialization::PageWithCachedMetadata.new(page)
        end

        super(page, options)
      end
    end
  end
end
