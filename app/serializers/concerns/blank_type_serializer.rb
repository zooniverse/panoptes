module BlankTypeSerializer
  extend ActiveSupport::Concern

  module ClassMethods
    def blank_serializer
      @blank_serializer ||= BlankSerializer.new(self)
    end

    def attributes(*attrs)
      attr_with_opts = attrs.last if attrs.last.is_a?(Hash)
      if attr_with_opts
        attrs[0..-2].concat(attr_with_opts.to_a)
      else
        attrs
      end.each do |attr|
        attribute(*attr)
      end
    end

    def attribute(attr, opts={})
      set_type(attr, opts)
      super attr, opts
    end

    def define_attribute(attr, opts={}, &block)
      set_type(attr, opts)
      attribute(attr, opts)
      define_method attr, &block
    end

    private

    def set_type(attr, opts)
      blank_serializer.type_map[attr] = opts[:type] if opts.has_key?(:type)
    end
  end

  class BlankSerializer
    attr_accessor :type_map

    def initialize(serializer)
      columns = begin
                  serializer.model_class.columns
                rescue ActiveRecord::StatementInvalid
                  []
                end

      @type_map = columns.reduce({}) do |map, column|
        map[column.name.to_sym] = column.sql_type unless map.has_key?(column.name.to_sym)
        map
      end
    end

    def default_value(attr, value)
      value.nil? ? default_for(attr) : value
    end

    def default_for(attr)
      case @type_map[attr].to_s
      when "integer", "decimal"
        0
      when "boolean"
        false
      else
        ""
      end
    end
  end

  def as_json(model, context={})
    data = super
    data.each do |attr, value|
      unless attr == :links
        data[attr] = self.class.blank_serializer.default_value(attr, value)
      end
    end
    data
  end
end
