require 'ddtrace/contrib/analytics'
require 'ddtrace/contrib/aws/ext'

module Datadog
  module Contrib
    module Aws
      # A Seahorse::Client::Plugin that enables instrumentation for all AWS services
      class Instrumentation < Seahorse::Client::Plugin
        def add_handlers(handlers, _)
          handlers.add(Handler, step: :validate)
        end
      end

      # Generates Spans for all interactions with AWS
      class Handler < Seahorse::Client::Handler
        def call(context)
          tracer.trace(Ext::SPAN_COMMAND) do |span|
            @handler.call(context).tap do
              annotate!(span, ParsedContext.new(context))
            end
          end
        end

        private

        def filter(path, resource)
          # Remove numbers from path & query string
          path = path.gsub(/=[0-9]\d*/, '=XXXXX') # query param
          path = path.gsub(/\/[0-9]\d*/, '/XXXXX') # path

          if !resource.nil? && resource.include?("s3")
            # if S3, remove filename entirely
            tmp = path.split("/")
            tmp.pop
            path = tmp.join("/")
          end

          return path
        end

        def annotate!(span, context)
          span.service = configuration[:service_name]
          span.span_type = Datadog::Ext::AppTypes::WEB
          span.name = Ext::SPAN_COMMAND
          span.resource = context.safely(:resource)

          # Set analytics sample rate
          if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
            Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
          end

          span.set_tag(Ext::TAG_AGENT, Ext::TAG_DEFAULT_AGENT)
          span.set_tag(Ext::TAG_OPERATION, context.safely(:operation))
          span.set_tag(Ext::TAG_REGION, context.safely(:region))
          if configuration[:filter_aws_path]
            span.set_tag(Ext::TAG_PATH, filter(context.safely(:path), context.safely(:resource)))
          else 
            span.set_tag(Ext::TAG_PATH, context.safely(:path))
          end
          span.set_tag(Ext::TAG_HOST, context.safely(:host))
          span.set_tag(Datadog::Ext::HTTP::METHOD, context.safely(:http_method))
          span.set_tag(Datadog::Ext::HTTP::STATUS_CODE, context.safely(:status_code))
        end

        def tracer
          configuration[:tracer]
        end

        def configuration
          Datadog.configuration[:aws]
        end
      end
    end
  end
end
