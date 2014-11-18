module Activatable
  extend ActiveSupport::Concern

  included do
    enum activated_state: [:active, :inactive]
    scope :active, -> { where(actived_state: :active) }
    scope :disabled, -> { where(actived_state: :inactive) }
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
