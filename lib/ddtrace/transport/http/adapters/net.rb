require 'ddtrace/transport/response'
require 'ddtrace/vendor/multipart-post/net/http/post/multipart'

module Datadog
  module Transport
    module HTTP
      module Adapters
        # Adapter for Net::HTTP
        class Net
          attr_reader \
            :hostname,
            :port,
            :timeout,
            :ssl

          DEFAULT_TIMEOUT = 30

          def initialize(hostname, port, options = {})
            @hostname = hostname
            @port = port
            @timeout = options[:timeout] || DEFAULT_TIMEOUT
            @ssl = options.key?(:ssl) ? options[:ssl] == true : false
          end

          def open
            # Open connection
            ::Net::HTTP.start(hostname, port, open_timeout: timeout, read_timeout: timeout, use_ssl: ssl) do |http|
              yield(http)
            end
          end

          def call(env)
            if respond_to?(env.verb)
              send(env.verb, env)
            else
              raise UnknownHTTPMethod, env
            end
          end

          def post(env)
            post = nil

            if env.form.empty?
              post = ::Net::HTTP::Post.new(env.path, env.headers)
              post.body = env.body
            else
              post = ::Datadog::Vendor::Net::HTTP::Post::Multipart.new(
                env.path,
                env.form,
                env.headers
              )
            end

            # Connect and send the request
            http_response = open do |http|
              http.request(post)
            end

            # Build and return response
            Response.new(http_response)
          end

          # Raised when called with an unknown HTTP method
          class UnknownHTTPMethod < StandardError
            attr_reader :verb

            def initialize(verb)
              @verb = verb
            end

            def message
              "No matching Net::HTTP function for '#{verb}'!"
            end
          end

          # A wrapped Net::HTTP response that implements the Transport::Response interface
          class Response
            include Datadog::Transport::Response

            attr_reader :http_response

            def initialize(http_response)
              @http_response = http_response
            end

            def payload
              return super if http_response.nil?
              http_response.body
            end

            def code
              return super if http_response.nil?
              http_response.code.to_i
            end

            def ok?
              return super if http_response.nil?
              code.between?(200, 299)
            end

            def unsupported?
              return super if http_response.nil?
              code == 415
            end

            def not_found?
              return super if http_response.nil?
              code == 404
            end

            def client_error?
              return super if http_response.nil?
              code.between?(400, 499)
            end

            def server_error?
              return super if http_response.nil?
              code.between?(500, 599)
            end
          end
        end
      end
    end
  end
end
