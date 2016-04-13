require 'experiments/basic_experiment'

module Experiments
  def self.for(name)
    BasicExperiment
  end
end
