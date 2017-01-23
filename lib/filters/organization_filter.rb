module ActiveInteraction
  class OrganizationFilter < Filter
    register :organization

    def cast(value, context)
      schema = OrganizationUpdateSchema.schema[:properties]
      included_keys = value.keys.map(&:to_sym)
      if included_keys.all? {|s| schema.key? s } && valid?(value)
        value
      else
        raise InvalidValueError, "#{name}: #{describe(value)}"
      end
    end

    def valid?(value)
      OrganizationUpdateSchema.new.validate!(value) == nil
    end
  end
end
