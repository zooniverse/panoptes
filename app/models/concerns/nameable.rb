module Nameable
  extend ActiveSupport::Concern

  class UnknownNameableModel < StandardError; end

  included do
    has_one :owner_name, as: :resource, autosave: true, dependent: :destroy
    validates :owner_name, presence: true
    validate  :consistent_owner_name
  end

  module ClassMethods
    def find_by_name(name)
      return nil if name.blank?
      if owner_name = OwnerName.where(name: name.downcase).first
        owner_name.resource
      end
    end
  end

  def name
    owner_name.name
  end

  private

  def consistent_owner_name
    return if owner_name.nil? || owner_name.name.blank?
    unless owner_name.name.match(/#{model_uniq_name_value}/i)
      self.errors.add(model_uniq_name_attribute, "inconsistent, match the owner_name#name value")
    end
  end

  def model_uniq_name_value
    self.send(model_uniq_name_attribute)
  end

  def model_uniq_name_attribute
    case
    when self.is_a?(User)
      :login
    when self.is_a?(UserGroup)
      :display_name
    else
      raise UnknownNameableModel.new("Unknown instance type when comparing resource to owner_name consistency")
    end
  end
end
