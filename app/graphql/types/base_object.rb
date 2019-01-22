module Types
  class BaseObject < GraphQL::Schema::Object
    private

    def apply_filters(initial_scope, filters)
      scope = filters.reduce(initial_scope) do |scope, (filter, value)|
        if scope.nil?
          scope
        else
          scope.where(filter => value)
        end
      end

      Pundit.policy!(context[:api_user], scope).scope_for(:index)
    end
  end
end
