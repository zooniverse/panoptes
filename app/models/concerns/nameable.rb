module Nameable
  extend ActiveSupport::Concern

  class UnknownNameableModel < StandardError; end

  included do
    attr_accessible :name
    has_one :uri_name, as: :resource, autosave: true, dependent: :destroy
    validates :uri_name, presence: true
    validate  :consistent_uri_name
  end

  module ClassMethods
    def find_by_name(n)
      UriName.where(name: n).first.resource
    end
  end

  def name=(n)
    if uri_name
      self.uri_name.name = n
    else
      self.uri_name = UriName.new(name: n, resource: self)
    end
  end

  def name
    uri_name.name
  end

  private

  def consistent_uri_name
    if uri_name && !uri_name.name.match(/#{model_uniq_name_value}/i)
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
