module Configurable
  def config_file=(file_name)
    @config_file = "config/#{file_name}.yml"
  end

  def configuration
    @configuration ||= begin
                         config = YAML.load(ERB.new(File.read(Rails.root.join(@config_file))).result)
                         config[Rails.env].symbolize_keys
                       rescue Errno::ENOENT, NoMethodError
                         {  }
                       end
  end
end
