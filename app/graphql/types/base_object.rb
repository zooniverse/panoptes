module Types
  class BaseObject < GraphQL::Schema::Object
    # This method is part of the graphql-ruby API. It is called automatically
    # whenever any object defines an Array-type field.  Its job is then to take
    # whatever the field definition returned and filter it down to only
    # accessible objects.
    #
    # Our default implementation is to always run everything through Pundit to
    # scope it to accessible (indexable) records. This breaks if `items` is an
    # array of objects instead of an ActiveRecord-relation.  If that is to be
    # supported, a type should override this method.  This way we're secure by
    # default, and raise an exception if you use it in a non-default way.
    #
    # This also doesn't apply to Mutations. The execute method of mutations
    # needs to do its own scoping. (It does of course apply to fields returned
    # from a mutation, just not to the question of "can I modify this record?"
    def self.scope_items(items, context)
      puts "scoping items: #{items.class}"
      Pundit.policy!(context[:api_user], items).scope_for(:index)
    end

    private

    def apply_filters(initial_scope, filters)
      filters.reduce(initial_scope) do |scope, (filter, value)|
        if scope.nil?
          scope
        else
          scope.where(filter => value)
        end
      end
    end
  end
end
