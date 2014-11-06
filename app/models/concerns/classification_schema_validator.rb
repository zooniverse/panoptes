class ClassificationSchemaValidator

  class InvalidSchema < StandardError; end
  class NonExpertUser < StandardError; end

  def initialize(classification)
    @classification = classification
  end

  def validate
    validate_gold_standard
  end

  private

  def classification
    @classification
  end

  def project
    @project ||= classification.project
  end

  def user
    @user ||= classification.user
  end

  def validate_gold_standard
    if classification.gold_standard
      unless project.expert_classifier?(user)
        raise NonExpertUser.new("Classifier is not a project expert")
      end
    elsif classification.gold_standard == false
       raise InvalidSchema.new('Gold standard can not be set to false')
    end
  end
end
