if Rails.env.development? || Rails.env.test?
  StrongMigrations.start_after = 20190624094308
end
