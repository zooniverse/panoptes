module ControlControl
  module Resource
    def can(action, filter=nil, &block)
      @can_filters ||= Hash.new
      @can_filters[action] ||= Array.new
      @can_filters[action] << (filter.nil? ? block : filter)
      create_method(action)
    end

    def can_filters
      @can_filters
    end

    def create_method(name)
      method_name = "can_#{ name }?".to_sym
      return if self.method_defined?(method_name)
      
      define_method method_name do |actor, *args|
        self.class.can_filters[name].any? do |filter|
          if filter.is_a?(Proc)
            instance_exec(actor, *args, &filter)
          else
            send(filter, actor, *args)
          end
        end
      end
    end
  end
end
