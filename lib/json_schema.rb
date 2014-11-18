class JsonSchema
  class ValidationError < StandardError; end
  
  class Builder
    attr_reader :schema
    
    def initialize(schema={})
      @schema = schema
    end
    
    def build(&block)
      instance_exec(&block)
      schema
    end

    private

    def additional_properties(bool)
      schema[:additionalProperties] = bool
    end
    
    def title(title)
      schema[:title] = title
    end

    def type(type)
      schema[:type] = type
    end

    def description(desc)
      schema[:description] = desc
    end

    def required(*props)
      schema[:required] = props
    end

    def items(*items, &block)
      raise StandardError unless schema[:type] == 'array'
      schema[:items] = subschema(&block)
    end

    def property(prop, &block)
      raise StandardError unless schema[:type] == 'object'
      schema[:properties] ||= {}
      schema[:properties][prop.to_sym] = subschema(&block)
    end

    def one_of(*schemas)
      schema[:oneOf] = schemas.map do |schema|
        case schema
        when String, Symbol
          { "$refs" => "#/definitions/#{ schema }" }
        when Hash
          schema
        end
      end
    end

    def define(key, &block)
      schema[:definitions] ||= {}
      schema[:definitions][key.to_sym] = subschema(&block)
    end

    def subschema(&block)
      Builder.new.build(&block)
    end
  end
  
  def self.build(&block)
    new(Builder.new.build(&block))
  end

  def self.build_eval(str)
    builder = Builder.new
    builder.instance_eval(str)
    new(builder.schema)
  end
  
  def initialize(schema)
    @schema = schema
  end

  def validate!(json)
    errors = JSON::Validator.fully_validate(@schema, json)
    raise ValidationError, errors unless errors.empty?
  end
end
