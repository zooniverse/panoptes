class PunditScopeTester
  def initialize(klass, user)
    @klass = klass
    @user = user
  end

  def index
    Pundit.policy!(@user, @klass).scope_for(:index)
  end

  def show
    Pundit.policy!(@user, @klass).scope_for(:show)
  end

  def update
    Pundit.policy!(@user, @klass).scope_for(:update)
  end

  def destroy
    Pundit.policy!(@user, @klass).scope_for(:destroy)
  end

  def update_links
    Pundit.policy!(@user, @klass).scope_for(:update_links)
  end

  def destroy_links
    Pundit.policy!(@user, @klass).scope_for(:destroy_links)
  end

  def versions
    Pundit.policy!(@user, @klass).scope_for(:versions)
  end

  def version
    Pundit.policy!(@user, @klass).scope_for(:version)
  end

  def translate
    Pundit.policy!(@user, @klass).scope_for(:translate)
  end

  def deactivate
    Pundit.policy!(@user, @klass).scope_for(:deactivate)
  end

  def project
    Pundit.policy!(@user, @klass).scope_for(:project)
  end

  def incomplete
    Pundit.policy!(@user, @klass).scope_for(:incomplete)
  end
end
