module Linkable
  extend ActiveSupport::Concern

  included do
    @link_scopes = Hash.new([:default_link_to_scope, :user])
  end

  module ClassMethods
    def can_be_linked(relation, scope, *args)
      rel_class = relation.to_s.singularize.camelize.constantize
      @link_scopes[rel_class] = [scope] | args
    end

    def link_to_resource(model, user, *args)
      method, *default_args = @link_scopes[model.class]
      scope_args = link_scope_arguments(default_args, model, user, args)
      send(method, *scope_args)
    end

    protected

    def link_scope_arguments(default_args, model, user, additional_args)
      (default_args | additional_args).map do |item|
        case item
        when :user
          user
        when :model
          model
        else
          item
        end
      end
    end

    def default_link_to_scope(user)
      scope_for(:show, user)
    end
  end
end
