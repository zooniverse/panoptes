module CacheModelVersion
  extend ActiveSupport::Concern

  included do
    after_save :update_workflow_version_cache
  end

  def current_version_number
    super || calculate_model_version
  end

  private

  def update_workflow_version_cache
    update_column(:current_version_number, calculate_model_version)
  end

  def calculate_model_version
    ModelVersion.version_number(self)
  end
end
