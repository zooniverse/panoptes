# https://github.com/github/scientist#making-science-useful
module Scientist::Experiment
  def self.new(name)
    CodeExperiment.cache_or_create(name)
  end
end
