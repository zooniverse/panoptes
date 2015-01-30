module Activatable
  extend ActiveSupport::Concern

  included do
    enum activated_state: [:active, :inactive]
    self.singleton_class.send(:alias_method, :disabled, :inactive)
  end

  def disabled?
    activated_state == "inactive"
  end

  def disable!
    inactive!
  end

  def enable!
    active!
  end
end
