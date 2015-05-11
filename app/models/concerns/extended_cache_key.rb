module ExtendedCacheKey
  extend ActiveSupport::Concern

  included do
    @included_associations = []
    @included_resource_methods = []
  end

  module ClassMethods
    def cache_by_association(*associations)
      associations.each do |association|
        if self.reflect_on_association(association) && !@included_associations.include?(association)
          @included_associations << association
        end
      end
    end

    def cache_by_resource_method(*resource_methods)
      resource_methods.each do |method|
        if self.method_defined?(method) && !@included_resource_methods.include?(method)
          @included_resource_methods << method
        end
      end
    end

    def included_associations
      @included_associations
    end

    def included_resource_methods
      @included_resource_methods
    end
  end

  def cache_key
    cache_key = super
    associations_cache_key = compound_association_cache_keys.join("+")
    methods_cache_key = compound_method_cache_keys.join("")
    create_append_cache_key(cache_key, methods_cache_key, associations_cache_key)
  end

  private

  def compound_association_cache_keys
    self.class.included_associations.map do |association|
      self.send(association).map(&:cache_key).join("+")
    end
  end

  def compound_method_cache_keys
    self.class.included_resource_methods.map do |method|
      "#{method}:#{self.send(method)}"
    end
  end

  def create_append_cache_key(key_base, methods_key, associations_key)
    key_base.tap do |base|
      base << "+#{methods_key}" unless methods_key.empty?
      base << "+#{associations_key}" unless associations_key.empty?
    end
  end
end
