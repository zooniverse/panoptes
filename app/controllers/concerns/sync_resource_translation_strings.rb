module SyncResourceTranslationStrings
  extend ActiveSupport::Concern

  included do
    after_action :sync_translatable_resource_strings, only: %i(update create)
  end

  private

  def sync_translatable_resource_strings
    translable_resources.each do |resource|
      TranslationSyncWorker.perform_async(
        resource.class.name,
        resource.id,
        resource.primary_language
      )
    end
  end

  def translable_resources
    controlled_resources | created_resources
  end
end
