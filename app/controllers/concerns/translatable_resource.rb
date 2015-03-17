module TranslatableResource
  extend ActiveSupport::Concern

  def controlled_resources
    @controlled_resources ||=
      case action_name
      when "show", "index"
        resource_class.load_with_languages(super, current_languages)
      when "version", "versions"
        super
      else
        resource_class.load_with_languages(super)
      end
  end
end
