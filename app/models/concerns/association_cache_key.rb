module AssociationCacheKey
  extend ActiveSupport::Concern

  included do
    @included_associations = []
    @included_resource_methods = []
  end

  module ClassMethods
    def cache_by_association(*associations)
      associations.each do |association|
        if self.reflect_on_association(association)
          @included_associations << association
        end
      end
    end

    def cache_by_resource_method(*resource_methods)
      resource_methods.each do |method|
        @included_resource_methods << method if self.method_defined?(method)
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
    methods_cache_key = compound_method_cache_keys.join("+")
    "#{cache_key}+#{associations_cache_key}+#{methods_cache_key}"
  end

  private

  def compound_association_cache_keys
    self.class.included_associations.map do |association|
      self.send(association).map(&:cache_key).join("+")
    end
  end

  def compound_method_cache_keys
    self.class.included_resource_methods.map do |method|
      "#{method}/#{self.send(method)}"
    end
  end
end
