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

    experiment
  rescue ActiveRecord::RecordNotUnique
    new(name: name, enabled_rate: 0)
  end

  def self.reset_cache!
    Thread.current[:code_experiment_cache] = nil
  end

  def self.reload_cache_for(name)
    experiment = find_or_create_by!(name: name)
    experiment.readonly!
    Thread.current[:code_experiment_cache][name] = [Time.zone.now, experiment]
    experiment
  end

  def enabled?
    return false unless Librato::Metrics.client.email.present?
    enabled_rate > 0 && rand < enabled_rate
  end

  def publish(result)
    # Store the timing for the control value,
    librato.add "science.#{name}.control" => {type: :gauge, value: result.control.duration}
    # for the candidate (only the first, see "Breaking the rules" below,
    librato.add "science.#{name}.candidate" => {type: :gauge, value: result.candidates.first.duration}

    # and counts for match/ignore/mismatch:
    if result.matched?
      librato.add "science.#{name}.matched" => {type: :counter, value: 1}
    elsif result.ignored?
      librato.add "science.#{name}.ignored" => {type: :counter, value: 1}
    else
      librato.add "science.#{name}.mismatched" => {type: :counter, value: 1}
    end

    librato.submit
  end

  def librato
    @librato ||= Librato::Metrics::Queue.new(source: Rails.env)
  end
end
