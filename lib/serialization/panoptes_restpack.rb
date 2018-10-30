module Serialization
  module PanoptesRestpack
    extend ActiveSupport::Concern

    included do
      include RestPack::Serializer
      include InstanceMethodOverrides
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
        page_scope = paging_scope(params, scope, context)
        super(params, page_scope, context)
      end

      def paging_scope(params, scope, context)
        preload_relations = preloads | param_preloads(params)

        unless preload_relations.empty?
          scope = scope.preload(*preload_relations)
        end

        scope
      end

      private

      def param_preloads(params)
        PreloadsFromIncludeParams.new(params, can_includes).extract
      end

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

    module InstanceMethodOverrides
      # The original method in RestPack only serializes links if they aren't
      # blank. This means that has-many associations with no records don't
      # serialize as an empty array, but instead are left out completely. This
      # is undesirable because it means the schema of the JSON responses we send
      # out varies record by record, and also means that you can't tell from
      # just the JSON records what associations a model has.
      def add_links(model, data)
        self.class.associations.each do |association|
          data[:links] ||= {}
          links_value = case association.macro
                        when :belongs_to
                          if association.polymorphic?
                            linked_id = model.send(association.foreign_key)
                              .try(:to_s)
                            linked_type = model.send(association.foreign_type)
                              .try(:to_s)
                              .demodulize
                              .underscore
                              .pluralize
                            {
                              href: "/#{linked_type}/#{linked_id}",
                              id: linked_id,
                              type: linked_type
                            }
                          else
                            model.send(association.foreign_key).try(:to_s)
                          end
                        when :has_one
                          model.send(association.name).try(:id).try(:to_s)
                        else
                          if model.send(association.name).loaded?
                            model.send(association.name).collect { |associated| associated.id.to_s }
                          else
                            model.send(association.name).pluck(:id).map(&:to_s)
                          end
                        end

          # https://github.com/zooniverse/restpack_serializer/blob/a0c2bc4725dbdd86783f09c88054280e110da752/lib/restpack_serializer/serializable.rb#L101
          # PATCH: Compared to the original above, we now add all links even when blank
          data[:links][association.name.to_sym] = links_value
        end

        data
      end
    end

    # Helper class to extract the valid preloadable relations from params
    # and handle the special owners relation from RoleControl::Owned
    class PreloadsFromIncludeParams
      attr_reader :params, :allowed_includes

      def initialize(params, allowed_includes)
        @params = params
        @allowed_includes = allowed_includes
      end

      def extract
        return [] unless params.key?(:include)

        preloads = preloads_from_params

        unless preloads.include?(:owners)
          return preloads
        end

        includable_preloads = preloads - [ :owners ]
        includable_preloads << [ owner: { identity_membership: :user } ]
        includable_preloads
      end

      private

      def preloads_from_params
        include_params = params[:include].split(',').map(&:to_sym)
        Array.wrap(include_params & allowed_includes)
      end
    end
  end
end
