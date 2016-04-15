# https://github.com/github/scientist#making-science-useful
module Scientist::Experiment
  def self.new(name)
    # Having to go mix in Scientist everytime you use it, and removing
    # when done makes no sense. Also configuring which experiment class
    # to use by monkey patching #new is horrible.

    raise "Use CodeExperiment.run instead"
  end
end
