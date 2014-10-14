module Linkable
  extend ActiveSupport::Concern

  included do
    @link_scopes = Hash.new([:default_link_to_scope, :actor])
  end

  module ClassMethods
    def can_be_linked(relation, scope, *args)
      rel_class = relation.to_s.singularize.camelize.constantize
      @link_scopes[rel_class] = [scope] | args
    end

    def link_to_resource(model, actor, *args)
      method, *default_args = @link_scopes[model.class]
      scope_args = link_scope_arguments(default_args, model, actor, args)
      send(method, *scope_args)
    end

    protected

    def link_scope_arguments(default_args, model, actor, additional_args)
      (default_args | additional_args).map do |item|
        case item
        when :actor
          actor
        when :model
          model
        else
          item
        end
      end
    end

    def default_link_to_scope(actor)
      scope_for(:show, actor)
    end
  end
end
