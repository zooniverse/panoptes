class HttpCacheable
  CACHEABLE_RESOURCES = {
    subjects: "public max-age: 60",
    projects: "public max-age: 60"
  }.freeze

  attr_reader :controlled_resources, :resource_class, :resource_symbol

  def initialize(controlled_resources)
    @controlled_resources = controlled_resources
    @resource_class = controlled_resources.klass
    @resource_symbol = resource_class.model_name.plural.to_sym
  end

  def public_resources?
    return false unless resource_cache_directive

    private_resources = if resource_class.respond_to?(:parent_class)
      any_private_parent_resources?
    else
      any_private_resources?
    end

    !private_resources
  end

  private

  def resource_cache_directive
    CACHEABLE_RESOURCES[resource_symbol]
  end

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
end
