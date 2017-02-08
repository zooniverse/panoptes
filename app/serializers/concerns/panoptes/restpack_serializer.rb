module Panoptes
  module RestpackSerializer
    extend ActiveSupport::Concern

    included do
      include RestPack::Serializer
      extend ClassMethodOverrides
    end

    module ClassMethods
      def preload(*preloads)
        @preloads ||= []
        @preloads += preloads
      end

      def preloads
        @preloads || []
      end
    end

    module ClassMethodOverrides
      def page(params = {}, scope = nil, context = {})
        if params[:include]
          param_preloads = params[:include].split(',').map(&:to_sym) & self.can_include
        end
        preload_relations = self.preloads | Array.wrap(param_preloads)
        unless preload_relations.empty?
          scope = scope.preload(*preload_relations)
        end

        super(params, scope, context)
      end
    end
  end
end
