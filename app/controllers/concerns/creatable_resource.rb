module CreatableResource
  def create
    resource_class.new(create_params)
  end
end
