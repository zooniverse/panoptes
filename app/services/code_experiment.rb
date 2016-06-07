class CodeExperiment
  include ActiveModel::Model
  include Scientist::Experiment

  attr_accessor :id, :name, :enabled_rate, :always_enabled_for_admins, :cached_at

  def self.run(name, opts={})
    config = CodeExperimentConfig.cache_or_create(name)
    experiment = new(config)
    experiment.context({})

    yield experiment

    test = opts[:run] if opts
    experiment.run(test)
  end

  def self.reporter
    @reporter ||= CodeExperiments::LibratoReporter.new
  end

  def self.reporter=(reporter)
    @reporter = reporter
  end

  def enabled?
    if always_enabled_for_admins && admin_user?
      true
    else
      enabled_rate > 0 && rand < enabled_rate
    end
  end

  def publish(result)
    self.class.reporter.publish(self, result)
  end

  def admin_user?
    !!context[:user]&.is_admin?
  end
end
