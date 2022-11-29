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

  # Used by classifications controller:
  def project
    Pundit.policy!(@user, @klass).scope_for(:project)
  end

  # Used by classifications controller:
  def incomplete
    Pundit.policy!(@user, @klass).scope_for(:incomplete)
  end

  # Used by projects, workflows, subejct_sets controller:
  def create_classifications_export
    Pundit.policy!(@user, @klass).scope_for(:create_classifications_export)
  end

  # Used by projects controller:
  def create_subjects_export
    Pundit.policy!(@user, @klass).scope_for(:create_subjects_export)
  end

  # Used by projects controller:
  def create_workflows_export
    Pundit.policy!(@user, @klass).scope_for(:create_workflows_export)
  end

  # Used by projects controller:
  def create_workflow_contents_export
    Pundit.policy!(@user, @klass).scope_for(:create_workflow_contents_export)
  end

  # Used by workflows controller:
  def retire_subjects
    Pundit.policy!(@user, @klass).scope_for(:retire_subjects)
  end

  # Used by workflows controller:
  def unretire_subjects
    Pundit.policy!(@user, @klass).scope_for(:unretire_subjects)
  end
end
