class CodeExperimentConfig < ActiveRecord::Base
  include Scientist::Experiment
  CACHE_TIME = 5.minutes

  validates_presence_of :name
  validates_uniqueness_of :name

  def self.cache_or_create(name)
    Thread.current[:code_experiment_cache] ||= {}
    name = name.to_s

    if config = Thread.current[:code_experiment_cache][name]
      if config[:cached_at] < CACHE_TIME.ago
        config = reload_cache_for(name)
      end
    else
      config = reload_cache_for(name)
    end

    config.with_indifferent_access
  rescue ActiveRecord::RecordNotUnique
    new(name: name, enabled_rate: 0).attributes
  end

  def self.reset_cache!
    Thread.current[:code_experiment_cache] = nil
  end

  def self.reload_cache_for(name)
    model = find_or_create_by!(name: name)
    config = model.attributes.merge(cached_at: Time.now)
    Thread.current[:code_experiment_cache][name] = config
  end
end
