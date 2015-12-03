module RetirementSchemes
  CRITERIA = {
    "never_retire" => NeverRetire,
    "classification_count" => ClassificationCount
  }

  def self.for(criteria)
    CRITERIA.fetch(criteria)
  rescue KeyError
    raise StandardError, 'invalid retirement scheme'
  end
end
