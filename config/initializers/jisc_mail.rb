module Panoptes
  def self.jisc_mail_config
    @jisc_mail_config ||= begin
                            file = Rails.root.join('config/jisc_mail.yml')
                            YAML.load(File.read(file))[Rails.env].symbolize_keys
                          rescue Errno::ENOENT, NoMethodError
                            {  }
                          end
  end
end

Panoptes.jisc_mail_config
