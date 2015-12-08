configuration = begin
                  file = Rails.root.join('config/storage.yml')
                  YAML.load(File.read(file))[Rails.env].symbolize_keys
                rescue Errno::ENOENT, NoMethodError
                  {adapter: "default"}
                end

MediaStorage.adapter(configuration.delete(:adapter), **configuration)
