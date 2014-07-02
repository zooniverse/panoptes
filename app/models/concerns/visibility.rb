module Visibility
  extend ActiveSupport::Concern

  included do |klass|
    class << self
      attr_accessor :visibility_levels
    end
    
    klass.class_eval do
      scope :publicly_visible, ->{ where(visibility: 'public') }
    end
    
    self.visibility_levels = { public: [] }
  end

  module ClassMethods
    def policy_class
      include?(Ownable) ? OwnedVisibilityPolicy : super
    end
    
    def visibility_level(level, *roles)
      visibility_levels[level] = roles
    end
  end

  def current_visibility
    (visibility || :private).to_sym
  end

  def is_public?
    :public == current_visibility
  end

  def roles_visible_to
    self.class.visibility_levels[current_visibility].map do |role|
      {name: role, resource: self}
    end
  end

  def has_access?(actor)
    is_public? || (!actor.nil? && actor.has_any_role?(*roles_visible_to))
  end
end

