module Visibility
  extend ActiveSupport::Concern

  included do
    @visibility_levels = {public: []}
  end

  module ClassMethods 
    def visibility_level(level, *roles)
      @visibility_levels[level] = roles
    end

    def visibility_levels
      @visibility_levels
    end
  end

  def current_visibility
    visibility.to_sym
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

