module Nameable
  extend ActiveSupport::Concern

  class UnknownNameableModel < StandardError; end

  included do
    has_one :uri_name, as: :resource, autosave: true, dependent: :destroy
    validates :uri_name, presence: true
    validate  :consistent_uri_name
  end

  module ClassMethods
    def find_by_name(name)
      return nil if name.blank?
      if uri_name = UriName.where(name: name.downcase).first
        uri_name.resource
      end
    end
  end

  def name
    uri_name.name
  end

  private

  def consistent_uri_name
    return if uri_name.nil? || uri_name.name.blank?
    unless uri_name.name.match(/#{model_uniq_name_value}/i)
      self.errors.add(model_uniq_name_attribute, "inconsistent, match the uri_name#name value")
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
      raise UnknownNameableModel.new("Unknown instance type when comparing resource to uri_name consistency")
    end
  end
end
