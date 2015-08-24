require 'active_model/serializer/adapter/json_api/fragment_cache'

module Serialization
  class V1Adapter < ActiveModel::Serializer::Adapter
    def initialize(serializer, options = {})
      super
      serializer.root = true
      @hash = { serializer.type => [] }

      if fields = options.delete(:fields)
        @fieldset = ActiveModel::Serializer::Fieldset.new(fields, serializer.json_key)
      else
        @fieldset = options[:fieldset]
      end
    end

    def serializable_hash(options = {})
      if serializer.respond_to?(:each)
        serializer.each do |s|
          result = self.class.new(s, @options.merge(fieldset: @fieldset)).serializable_hash
          @hash[serializer.type] << result[serializer.type]

          if result[:linked]
            result[:linked].each do |type, data|
              @hash[:linked] ||= {}
              @hash[:linked][type] ||= []
              @hash[:linked] |= data
            end
          end
        end
      else
        @hash[serializer.type] = [attributes_for_serializer(serializer, @options)]
        add_resource_links(@hash[serializer.type][0], serializer)
      end
      @hash
    end

    def fragment_cache(cached_hash, non_cached_hash)
      root = false if @options.include?(:include)
      JsonApi::FragmentCache.new().fragment_cache(root, cached_hash, non_cached_hash)
    end

    private

    def add_links(resource, name, serializers)
      resource[:links] ||= {}
      resource[:links][name] = serializers.map { |serializer| serializer.id.to_s }
    end

    def add_link(resource, name, serializer, val=nil)
      resource[:links] ||= {}
      resource[:links][name] = nil

      if serializer && serializer.object
        resource[:links][name]= serializer.id.to_s
      end
    end

    def add_included(resource_name, serializers, parent = nil)
      unless serializers.respond_to?(:each)
        return unless serializers.object
        serializers = Array(serializers)
      end
      resource_path = [parent, resource_name].compact.join('.')
      if include_assoc?(resource_path)
        @hash[:linked] ||= {}

        serializers.each do |serializer|
          attrs = attributes_for_serializer(serializer, @options)

          add_resource_links(attrs, serializer, add_included: false)

          @hash[:linked][serializer.type] ||= []
          @hash[:linked][serializer.type].push(attrs) unless @hash[:linked][serializer.type].include?(attrs)
        end
      end

      serializers.each do |serializer|
        serializer.each_association do |name, association, opts|
          add_included(name, association, resource_path) if association
        end if include_nested_assoc? resource_path
      end
    end

    def attributes_for_serializer(serializer, options)
      if serializer.respond_to?(:each)
        result = []
        serializer.each do |object|
          options[:fields] = @fieldset && @fieldset.fields_for(serializer)
          result << cache_check(object) do
            options[:required_fields] = [:id, :type]
            attributes = object.attributes(options)
            attributes[:id] = attributes[:id].to_s
            attributes[:href] = "/#{serializer.type}/#{object.id}"
            attributes.delete(:type)
            result << attributes
          end
        end
      else
        options[:fields] = @fieldset && @fieldset.fields_for(serializer)
        options[:required_fields] = [:id, :type]
        result = cache_check(serializer) do
          result = serializer.attributes(options)
          result[:id] = result[:id].to_s
          result[:href] = "/#{serializer.type}/#{serializer.id}"
          result.delete(:type)
          result
        end
      end
      result
    end

    def include_assoc?(assoc)
      return false unless @options[:include]
      check_assoc("#{assoc}$")
    end

    def include_nested_assoc?(assoc)
      return false unless @options[:include]
      check_assoc("#{assoc}.")
    end

    def check_assoc(assoc)
      include_opt = @options[:include]
      include_opt = include_opt.split(',') if include_opt.is_a?(String)
      include_opt.any? do |s|
        s.match(/^#{assoc.gsub('.', '\.')}/)
      end
    end

    def add_resource_links(attrs, serializer, options = {})
      options[:add_included] = options.fetch(:add_included, true)

      serializer.each_association do |name, association, opts|
        attrs[:links] ||= {}

        if association.respond_to?(:each)
          add_links(attrs, name, association)
        else
          if opts[:virtual_value]
            add_link(attrs, name, nil, opts[:virtual_value])
          else
            add_link(attrs, name, association)
          end
        end

        if options[:add_included]
          Array(association).each do |association|
            add_included(name, association)
          end
        end
      end
    end
  end
end
