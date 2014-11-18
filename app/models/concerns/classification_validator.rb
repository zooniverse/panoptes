class ClassificationValidator

  def initialize(classification)
    @classification = classification
  end

  def validate_gold_standard
    if classification.gold_standard
      unless project.expert_classifier?(user)
        add_error(:gold_standard, 'classifier is not a project expert')
      end
    elsif classification.gold_standard == false
      add_error(:gold_standard, 'can not be set to false')
    end
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

  def add_error(field, message)
    classification.errors.add(field, message)
  end
end
