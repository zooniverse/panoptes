require 'ostruct'

config_file = begin
                YAML.load(File.read(Rails.root.join("config/firebase.yml")))
              rescue Errno::ENOENT => e
                {}
              end

rails_env_config = config_file.fetch(Rails.env, {}).symbolize_keys!

firebase_config = ActiveSupport::HashWithIndifferentAccess.new.tap do |fb|
  fb[:url] = rails_env_config[:url]
  fb[:token] = rails_env_config[:token]
end

FirebaseConfig = OpenStruct.new(firebase_config)
