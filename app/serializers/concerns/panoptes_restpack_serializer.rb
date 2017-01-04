module Panoptes
  module RestpackSerializer
    extend ActiveSupport::Concern

    included do
      include RestPack::Serializer
      extend ClassMethodOverrides
    end

    module ClassMethodOverrides
      def page(params = {}, scope = nil, context = {})
        if params[:include]
          param_preloads = params[:include].split(',').map(&:to_sym)
          preloads = param_preloads & self.can_include
          scope = scope.preload(*preloads)
        end

        super(params, scope, context)
      end
    end
  end
end
