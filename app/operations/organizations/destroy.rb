module Organizations
  class Destroy < Operation
    integer :id

    def execute
      Organization.transaction do
        organization = Organization.find(id)
        Activation.disable_instances!([organization])
      end
    end
  end
end
