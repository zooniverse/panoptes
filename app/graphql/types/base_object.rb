module Types
  class BaseObject < GraphQL::Schema::Object
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
