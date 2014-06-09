module Activateable
  extend ActiveSupport::Concern

  included do
    enum activated_state: [:active, :inactive]
    scope :active, -> { where(actived_state: :active) }
    scope :disabled, -> { where(actived_state: :inactive) }
    @activate_proxies = []
  end

  module ActivateProxyHasMany
    def disable!
      self.each do |rel|
        rel.disable!
      end
    end

    def enable!
      self.each do |rel|
        rel.enable!
      end
    end
  end

  module ClassMethods 
    def proxy_status(*args)
      @activate_proxies = args
    end

    def disable_relations!(instance)
      @activate_proxies.each do |r|
        instance.send(r).disable!
      end
    end

    def enable_relations!(instance)
      @activate_proxies.each do |r|
        instance.send(r).enable!
      end
    end
  end


  def disable!
    inactive!
    self.class.disable_relations!(self)
  end

  def enable!
    active!
    self.class.enable_relations!(self)
  end
end
