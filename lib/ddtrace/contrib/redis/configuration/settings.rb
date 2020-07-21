require 'ddtrace/contrib/configuration/settings'
require 'ddtrace/contrib/redis/ext'

module Datadog
  module Contrib
    module Redis
      module Configuration
        # Custom settings for the Redis integration
        class Settings < Contrib::Configuration::Settings
          option :analytics_enabled do |o|
            o.default { env_to_bool(Ext::ENV_ANALYTICS_ENABLED, false) }
            o.lazy
          end

          option :analytics_sample_rate do |o|
            o.default { env_to_float(Ext::ENV_ANALYTICS_SAMPLE_RATE, 1.0) }
            o.lazy
          end

          # PII can appear in cache keys 
          option :filter_redis_command do |o|
            o.default { env_to_bool(Ext::FILTER_REDIS_COMMAND, false) }
            o.lazy
          end

          option :service_name, default: Ext::SERVICE_NAME
        end
      end
    end
  end
end
