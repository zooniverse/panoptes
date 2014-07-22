require 'doorkeeper/server'

Doorkeeper::Server.class_eval do
  def parameters
    context.params
  end
end
