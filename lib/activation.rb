class Activation

  class << self

    def enable_instances!(instances=[])
      instances.map(&:enable!)
    end

    def disable_instances!(instances=[])
      instances.map(&:disable!)
    end
  end
end
