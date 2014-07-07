module Nameable
  extend ActiveSupport::Concern

  included do
    attr_accessible :name
    has_one :uri_name, as: :resource, dependent: :destroy
    validates :uri_name, presence: true
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
end
