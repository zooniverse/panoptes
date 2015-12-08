module Panoptes
  def self.user_limits
    @user_limits ||= begin
                       file = Rails.root.join('config/user_limits.yml')
                       YAML.load(File.read(file))[Rails.env].symbolize_keys
                     rescue Errno::ENOENT, NoMethodError
                       {  }
                     end
  end

  def self.max_subjects
    user_limits[:subjects]
  end
end

Panoptes.user_limits
