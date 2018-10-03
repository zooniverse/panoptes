module Workflows
  class Publish < Operation
    object :workflow

    def execute
      workflow.publish!
    end
  end
end
