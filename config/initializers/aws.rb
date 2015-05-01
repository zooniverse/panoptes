AWS.eager_autoload!

module Panoptes
  def self.aws_config
    @aws_config ||= begin
                      file = Rails.root.join('config/aws.yml')
                      YAML.load(File.read(file))[Rails.env].symbolize_keys
                    rescue Errno::ENOENT, NoMethodError
                      { subjects_bucket: "panoptes_development_subjects" }
                    end
  end

  def self.subjects_bucket
    @subjects_bucket ||= AWS::S3.new.buckets[aws_config[:subjects_bucket]]
  end

  def self.bucket_path
    @bucket_path ||= aws_config[:bucket_path]
  end

  def self.export_bucket_path
    @bucket_path ||= aws_config[:export_bucket_path]
  end
end

keys = Panoptes.aws_config.slice(:access_key_id, :secret_access_key)
AWS.config(keys) unless keys.empty?
