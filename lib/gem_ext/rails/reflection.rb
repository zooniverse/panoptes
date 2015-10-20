require 'active_record/reflection'
require 'belongs_to_many_association'

ActiveRecord::Reflection.module_eval do
  def self.create(macro, name, scope, options, ar)
    klass = case macro
            when :composed_of
              ActiveRecord::Reflection::AggregateReflection
            when :has_many
              ActiveRecord::Reflection::HasManyReflection
            when :has_one
              ActiveRecord::Reflection::HasOneReflection
            when :belongs_to
              ActiveRecord::Reflection::BelongsToReflection
            when :belongs_to_many
              BelongsToManyReflection
            else
              raise "Unsupported Macro: #{macro}"
            end

    reflection = klass.new(name, scope, options, ar)
    options[:through] ? ActiveRecord::Reflection::ThroughReflection.new(reflection) : reflection
  end

  class BelongsToManyReflection < ActiveRecord::Reflection::AssociationReflection
     def initialize(name, scope, options, active_record)
       super(name, scope, options, active_record)
     end

    def macro; :belongs_to_many; end

    def belongs_to?; true; end

    def collection?; true; end

    def foreign_key
      @foreign_key ||= case
                       when key = options[:foreign_key]
                         key
                       when key = options[:as]
                         "#{key}_ids"
                       else
                         "#{name.to_s.singularize}_ids"
                       end
    end

    def association_class
      BelongsToManyAssociation
    end

    def join_keys(association_klass)
      ActiveRecord::Reflection::AbstractReflection::JoinKeys
        .new(association_primary_key, foreign_key)
    end

    def join_id_for(owner)
      owner[foreign_key]
    end
  end
end
