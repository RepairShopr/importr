if Rails.env.production? || Rails.env.staging? || ENV['ROLLBAR_ACCESS_TOKEN'].present?
  require 'rollbar/rails'

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
    config.custom_data_method = -> { { heroku_app_name: ENV['HEROKU_APP_NAME'] } }

    config.use_sidekiq 'queue' => 'importer_logging' if Rails.env.production? || Rails.env.staging? # do not do this for dev ...
  end
end
