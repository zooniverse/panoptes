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

    def link_to(model, actor, *args)
      method, *default_args = @link_scopes[model.class]
      arguments = (default_args | args).map do |item|
        case item
        when :actor
          actor
        when :model
          model
        else
          item
        end
      end
      send(method, *arguments)
    end

    protected

    def default_link_to_scope(actor)
      scope_for(:show, actor)
    end
  end
end
