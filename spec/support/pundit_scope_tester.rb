class PunditScopeTester
  def initialize(klass, user)
    @klass = klass
    @user = user
  end

  def method_missing(method, *args)
    Pundit.policy!(@user, @klass).scope_for(method)
  end
end
