class Activation

  def self.enable_instances!(instances=[])
    instances.map(&:enable!)
  end

  def self.disable_instances!(instances=[])
    instances.map(&:disable!)
  end
end
