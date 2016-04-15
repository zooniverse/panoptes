class CodeExperiment < ActiveRecord::Base
  include Scientist::Experiment
  CACHE_TIME = 5.minutes

  has_paper_trail

  validates_presence_of :name
  validates_uniqueness_of :name

  def self.cache_or_create(name)
    Thread.current[:code_experiment_cache] ||= {}
    name = name.to_s

    if cache = Thread.current[:code_experiment_cache][name]
      load_time, experiment = cache
      if load_time < CACHE_TIME.ago
        experiment = reload_cache_for(name)
      end
    else
      experiment = reload_cache_for(name)
    end

    new(experiment.attributes).tap(&:readonly!)
  rescue ActiveRecord::RecordNotUnique
    new(name: name, enabled_rate: 0)
  end

  def self.reset_cache!
    Thread.current[:code_experiment_cache] = nil
  end

  def self.reload_cache_for(name)
    experiment = find_or_create_by!(name: name)
    Thread.current[:code_experiment_cache][name] = [Time.zone.now, experiment]
    experiment
  end

  def self.reporter
    @reporter ||= Experiments::LibratoReporter.new
  end

  def self.reporter=(reporter)
    @reporter = reporter
  end

  def enabled?
    enabled_rate > 0 && rand < enabled_rate
  end

  def publish(result)
    self.class.reporter.publish(self, result)
  end
end
