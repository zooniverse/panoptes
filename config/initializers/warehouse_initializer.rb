file = Rails.root.join('config/warehouse.yml')
configuration = YAML.load(File.read(file)).fetch(Rails.env).symbolize_keys

Warehouse.config(configuration.delete(:adapter), **configuration)
