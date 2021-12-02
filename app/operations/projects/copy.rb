module Projects
  class Copy < Operation
    object :user
    object :project

    def execute
      ProjectCopier.new(project.id, user.id).copy
    end
  end
end
