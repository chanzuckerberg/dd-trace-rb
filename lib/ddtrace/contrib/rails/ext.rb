module Datadog
  module Contrib
    module Rails
      # Rails integration constants
      module Ext
        APP = 'rails'.freeze
        ENV_ANALYTICS_ENABLED = 'DD_RAILS_ANALYTICS_ENABLED'.freeze
        ENV_ANALYTICS_SAMPLE_RATE = 'DD_RAILS_ANALYTICS_SAMPLE_RATE'.freeze
        ENV_DISABLE = 'DISABLE_DATADOG_RAILS'.freeze
        FILTER_EXCEPTION_MESSAGE = 'FILTER_EXCEPTION_MESSAGE'.freeze
        FILTER_EXCEPTION_TRACE = 'FILTER_EXCEPTION_TRACE'.freeze
      end
    end
  end
end
