class Operation < ActiveInteraction::Base
  class Error < ApiErrors::PanoptesApiError; end
  class Unauthenticated < Error; end
  class Unauthorized < Error; end

  class PreScopedOperation
    def initialize(operation_class, scope = {})
      @operation_class = operation_class
      @scope = scope
    end

    def new(hash = {})
      @operation_class.new(hash.merge(@scope))
    end

    def run(hash = {})
      @operation_class.run(hash.merge(@scope))
    end

    def run!(hash = {})
      @operation_class.run!(hash.merge(@scope))
    end

    def with(scope)
      PreScopedOperation.new(self, scope)
    end
  end

  def self.with(scope)
    PreScopedOperation.new(self, scope)
  end

  object :api_user, class: :ApiUser
end
