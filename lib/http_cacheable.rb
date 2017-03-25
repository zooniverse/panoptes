class HttpCacheable
  CACHEABLE_RESOURCES = %i(subjects projects workflows).freeze

  attr_reader :controlled_resources, :resource_class, :resource_symbol

  def initialize(controlled_resources)
    @controlled_resources = controlled_resources
    @resource_class = controlled_resources.klass
    @resource_symbol = resource_class.model_name.plural.to_sym
  end

  def public_resources?
    return false unless cacheable_resource?
    !controlled_resources_any_private?
  end

  def resource_cache_directive
    @resource_cache_directive ||=
      if CACHEABLE_RESOURCES.include?(resource_symbol)
        "#{public_private_directive} max-age: #{max_age_directive}"
      end
  end

  private

  def any_private_parent_resources?
    parent_fk_scope = controlled_resources.select(
      resource_class.parent_foreign_key
    )

    resource_class
      .parent_class
      .private_scope
      .where(id: parent_fk_scope)
      .exists?
  end

  def any_private_resources?
    controlled_resources.private_scope.exists?
  end

  def public_private_directive
    @public_private_directive ||=
      if Panoptes.flipper[:private_http_caching].enabled?
        "private"
      else
        "public"
      end
  end

  def max_age_directive
    @max_age_directive ||= ENV.fetch("HTTP_#{resource_symbol.to_s.upcase}_MAX_AGE", 60)
  end

  def cacheable_resource?
    Panoptes.flipper[:http_caching].enabled? && !!resource_cache_directive
  end

  def controlled_resources_any_private?
    if resource_class.respond_to?(:parent_class)
      any_private_parent_resources?
    else
      any_private_resources?
    end
  end
end
