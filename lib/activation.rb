class Activation
  def self.enable_instances!(instances=[])
    instances.each do |i|
      i.enable!
    end
  end

  def self.disable_instances!(instances=[])
    instances.each do |i|
      i.disable!
    end
  end
end
