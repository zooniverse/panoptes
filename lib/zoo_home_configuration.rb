module ZooHomeConfiguration 
  def self.use_zoo_home?
    Rails.configuration.database_configuration.has_key?("zooniverse_home_#{Rails.env}")
  end
end
