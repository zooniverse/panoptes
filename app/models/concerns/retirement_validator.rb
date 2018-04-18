class RetirementValidator
  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def validate
    return if empty_retirement_config?

    if invalid_valid_criteria?
      add_error(
        :"retirement.criteria",
        "Retirement criteria must be one of #{retirement_criteria.keys.join(', ')}"
      )
    end

    if invalid_count_option?
      add_error(
        :"retirement.options.count",
        "Retirement count must be a number"
      )
    end
  end

  private

  def add_error(field, message)
    workflow.errors.add(field, message)
  end

  def empty_retirement_config?
    workflow.retirement.empty?
  end

  def retirement_criteria
    @retirement_criteria ||= RetirementSchemes::CRITERIA
  end

  def invalid_valid_criteria?
    !retirement_criteria.keys.include?(workflow.retirement['criteria'])
  end

  def invalid_count_option?
    has_options = workflow.retirement.fetch("options", {})
    options_count = has_options.fetch("count", 0)
    !options_count.is_a?(Integer)
  end
end
