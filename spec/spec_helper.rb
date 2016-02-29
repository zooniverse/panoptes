ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "sidekiq/testing"
require "paper_trail/frameworks/rspec"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
  config.include APIRequestHelpers, type: :controller
  config.include APIResponseHelpers, type: :controller
  config.include APIResponseHelpers, type: :request
  config.include ValidUserRequestHelper, type: :request
  config.include CellectHelpers
  config.extend RSpec::Helpers::ActiveRecordMocks

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.use_transactional_fixtures = false
  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.filter_run_excluding disabled: true

  Devise.mailer = Devise::Mailer

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = :transaction
    ActionMailer::Base.deliveries.clear

    # Clears out the jobs for tests using the fake testing
    Sidekiq::Worker.clear_all

    case example.metadata[:sidekiq]
    when :fake
      Sidekiq::Testing.fake!
    when :inline
      Sidekiq::Testing.inline!
    when :feature
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end
  end

  config.before(:each, type: :controller) do
    stub_cellect_connection
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end
