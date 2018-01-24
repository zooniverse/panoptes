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
        translatable_language(resource)
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

  def translatable_language(resource)
    if resource.respond_to?(:primary_language)
      resource.primary_language
    else
      resource.language
    end
  end
end
