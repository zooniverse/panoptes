Rails.application.configure do
  ActiveSupport::Deprecation.silenced = true
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_files  = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { protocol: 'https',
                                               host: 'panoptes_test.zooniverse.org' }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  #turn off the rails cache store
  config.cache_store = :null_store

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  #hack to fix issue with doorkeeper not loading ControllerHelpers in test env
  # https://github.com/doorkeeper-gem/doorkeeper/issues/375
  config.to_prepare do
    Doorkeeper::ApplicationsController.helper Doorkeeper::Helpers::Controller
  end

  if ENV['DISABLE_TEST_LOGGING']
    # rubocop:disable Rails/Output
    puts 'Logs are being suppressed to speed up the test suite. ' \
         'Remove DISABLE_TEST_LOGGING env var to add logging back.'
    # rubocop:enable Rails/Output
    config.log_level = :warn
  end
end
