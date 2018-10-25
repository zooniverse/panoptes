class TranslationSyncWorker
  include Sidekiq::Worker

  attr_reader :resource_klass, :resource_id

  def perform(resource_class, resource_id, language)
    @resource_klass = resource_class.camelize.constantize
    @resource_id = resource_id

    translation = Translation.find_or_initialize_by(
      translated: translated_resource,
      language: language
    )
    translated_strings = TranslationStrings.new(translated_resource).extract
    translation.update_strings_and_versions(translated_strings, translated_resource.latest_version_id)
    translation.save!
  end

  private

  def translated_resource
    @translated_resource ||= resource_klass.find(resource_id)
  end
end
