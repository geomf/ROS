# Portions Copyright (C) 2015 Intel Corporation

require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'active_record/connection_adapters/postgis_adapter'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ROS
  class Application < Rails::Application
    initializer "active_record.initialize_database.override" do |app|

      ActiveSupport.on_load(:active_record) do
        if url = ENV['DATABASE_URL']
          ActiveRecord::Base.connection_pool.disconnect!
          parsed_url = URI.parse(url)
          config =  {
              adapter:             'postgis',
              host:                parsed_url.host,
              encoding:            'unicode',
              database:            parsed_url.path.split("/")[-1],
              port:                parsed_url.port,
              username:            parsed_url.user,
              password:            parsed_url.password
          }
          establish_connection(config)
        end
      end
    end
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end
end
