module PolymorphicResourceScope
  extend ActiveSupport::Concern

  module ClassMethods
    def polymorphic_column(column_name)
      @polymorphic_column ||= column_name
    end

    def polymorphic_column_name
      @polymorphic_column
    end
  end

  private

  def polymorphic_column_name
    self.class.polymorphic_column_name
  end

  def controlled_resources
    return @controlled_resources if @controlled_resources

    resource_scope = resource_class.where(
      "#{polymorphic_column_name}_id" => polymorphic_controlled_resourses.select(:id),
      "#{polymorphic_column_name}_type" => polymorphic_klass
    )
    if params.key?(:id)
      resource_scope = resource_scope.where(id: params[:id])
    end
    @controlled_resources = resource_scope
  end

  def polymorphic_controlled_resourses
    @polymorphic_controlled_resourses ||=
      find_controlled_resources(
        polymorphic_klass,
        polymorphic_ids,
        controlled_action
      )
  end

  # All users can create all resources by default,
  # to be sure they can create an associated resource we test
  # they can update the linked resource instead of :create
  # otherwise default to normal behaviour
  def controlled_action
    if action_name == "create"
      :update
    else
      controlled_scope
    end
  end

  def polymorphic_controlled_resourse
    @polymorphic_controlled_resourse ||= @polymorphic_controlled_resourses.first
  end

  def polymorphic_klass_name
    @polymorphic_klass_name ||= params.keys.find do |key|
      key.to_s.match(/_id/)
    end[0..-4]
  end

  def polymorphic_klass
    @polymorphic_klass ||= polymorphic_klass_name.camelize.constantize
  end

  def polymorphic_ids
    return @polymorphic_ids if @polymorphic_ids
    polymorphic_ids = if params.has_key?("#{ polymorphic_klass_name }_id")
                        params["#{ polymorphic_klass_name }_id"]
                      else
                        ''
                      end
    @polymorphic_ids = array_id_params(polymorphic_ids)
  end

  # check the user can update the linked polymorphic resource
  # so they can create a linked polymorphic resource for it
  # e.g. A user wants link a background media resource to Project.where(id: 1)
  def check_polymorphic_controller_resources
    unless polymorphic_controlled_resourses.exists?
      raise_no_resources_error
    end
  end

  def _resource_ids
    params["#{ polymorphic_klass_name }_id"] || super
  end

  def no_resources_error_message
    super(polymorphic_klass_name)
  end
end
