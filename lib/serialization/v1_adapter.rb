module Serialization
  class V1Adapter < ActiveModelSerializers::Adapter::Base
    def initialize(serializer, options = {})
      super
      @hash = { serializer.json_key => [] }
      @options = options

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
          @hash[serializer.json_key] << result[serializer.json_key]

          if result[:linked]
            result[:linked].each do |type, data|
              @hash[:linked] ||= {}
              @hash[:linked][type] ||= []
              @hash[:linked] |= data
            end
          end
        end
      else
        @hash[serializer.json_key] = [attributes_for_serializer(serializer, @options)]
        add_resource_links(@hash[serializer.json_key][0], serializer)
      end
      @hash
    end

    def fragment_cache(cached_hash, non_cached_hash)
      root = false if @options.include?(:include)
      JsonApi.new().fragment_cache(root, cached_hash, non_cached_hash)
    end

    private

    def add_links(resource, name, serializers)
      resource[:links] ||= {}
      resource[:links][name] = serializers.map { |serializer| serializer.object.id.to_s }
    end

    def add_link(resource, name, serializer, val=nil)
      resource[:links] ||= {}
      resource[:links][name] = nil

      if serializer && serializer.object
        resource[:links][name] = serializer.object.id.to_s
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

          @hash[:linked][serializer.json_key] ||= []
          @hash[:linked][serializer.json_key].push(attrs) unless @hash[:linked][serializer.json_key].include?(attrs)
        end
      end

      serializers.each do |serializer|
        serializer.associations.each do |association|
          add_included(association.name, association, resource_path) if association
        end if include_nested_assoc? resource_path
      end
    end

    def attributes_for_serializer(serializer, options)
      if serializer.respond_to?(:each)
        result = []
        serializer.each do |object|
          options[:fields] = @fieldset && @fieldset.fields_for(serializer)
          result << object.fetch(self) do
            options[:required_fields] = [:id, :type]
            attributes = object.attributes(options)
            attributes[:id] = attributes[:id].to_s
            attributes[:href] = "/#{serializer.json_key}/#{object.id}"
            attributes.delete(:type)
            result << attributes
          end
        end
      else
        options[:fields] = @fieldset && @fieldset.fields_for(serializer)
        options[:required_fields] = [:id, :type]
        result = serializer.fetch(self) do
          result = serializer.attributes
          result[:id] = result[:id].to_s
          result[:href] = "/#{serializer.json_key}/#{serializer.object.id}"
          result.delete(:type)
          result
        end
      end
      result
    end

    def include_assoc?(assoc)
      return false unless @options.key?(:include)

      check_assoc(assoc)
    end

    def include_nested_assoc?(assoc)
      return false unless @options.key?(:include)

      check_nested_assoc(assoc)
    end

    def check_assoc(assoc)
      include_opt = @options[:include]
      include_opt = include_opt.split(',') if include_opt.is_a?(String)

      # check if any of the included associations match the current association
      include_opt.any?(assoc)
    end

    def check_nested_assoc(assoc)
      include_opt = @options[:include]
      include_opt = include_opt.split(',') if include_opt.is_a?(String)

      # check if any of the included associations match the prefix path of the association
      # i.e. ${association}.path
      nested_assoc_pattern = "#{assoc}."
      include_opt.any? { |included_assoc| included_assoc.starts_with?(nested_assoc_pattern) }
    end

    def add_resource_links(attrs, serializer, options = {})
      options[:add_included] = options.fetch(:add_included, true)

      serializer.associations.each do |association|
        attrs[:links] ||= {}

        if association.lazy_association.serializer.respond_to?(:each)
          add_links(attrs, association.name, association.lazy_association.serializer)
        else
          if association.reflection.options[:virtual_value]
            add_link(attrs, association.name, nil, association.reflection.options[:virtual_value])
          else
            add_link(attrs, association.name, association.lazy_association.serializer)
          end
        end

        if options[:add_included]
          Array.wrap(association.lazy_association.serializer).each do |associated_serializer|
            add_included(association.name, associated_serializer)
          end
        end
      end
    end
  end
end
