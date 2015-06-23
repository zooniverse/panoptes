module Panoptes
  def self.frontend_configuration
    @frontend_conf ||= begin
                         file = Rails.root.join('config/frontend_redirect.yml')
                         YAML.load(File.read(file))[Rails.env].symbolize_keys
                       rescue Errno::ENOENT, NoMethodError
                         {  }
                       end
  end

  def self.frontend_url
    frontend_configuration[:base]
  end

  def self.password_reset_redirect
    if reset = frontend_configuration[:password_reset]
      "#{frontend_url}#{reset}"
    end
  end

  def self.unsubscribe_redirect
    if unsubscribe = frontend_configuration[:unsubscribe]
      "#{frontend_url}#{unsubscribe}"
    end
  end
end

Panoptes.frontend_configuration
