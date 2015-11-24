# Portions Copyright (C) 2015 Intel Corporation

require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'active_record/connection_adapters/postgis_adapter'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ROS
  class Application < Rails::Application
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end
end
