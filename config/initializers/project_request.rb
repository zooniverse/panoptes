module Panoptes
  def self.project_request
    @project_request ||= OpenStruct
      .new(**begin
               file = Rails.root.join('config/project_request.yml')
               YAML.load(File.read(file))[Rails.env].symbolize_keys
             rescue Errno::ENOENT, NoMethodError
               { }
             end)
  end
end

Panoptes.project_request
