# https://github.com/github/scientist#making-science-useful
module Scientist::Experiment
  def self.new(name)
    Experiments.for(name).new(name: name)
  end
end
