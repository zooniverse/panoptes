module SyncResourceTranslationStrings
  extend ActiveSupport::Concern

  included do
    after_action :sync_translatable_resource_strings, only: %i(update create)
  end

  private

  def sync_translatable_resource_strings
    translatable_resources.each do |resource|
      TranslationSyncWorker.perform_async(
        resource.class.name,
        resource.id,
        resource.translatable_language
      )
    end
  end

  def translatable_resources
    if action_name == "create"
      created_resources
    else
      controlled_resources
    end
  end
end
