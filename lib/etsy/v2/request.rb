module Etsy
  module V2
    class Request < BaseRequest
      BASE_PATH = '/v2'.freeze

      # Initialize a V2::Request
      #
      # @param [String] resource_path path to the API resource, i.e. '/shops/1/listings'
      # @param [Hash] parameters the options to initialize OAuth client and request params
      # @option parameters [String] :access_token access token of the user
      # @option parameters [String] :access_secret access secret of the user
      # @option parameters [String] :includes additional resources requested to include into the response
      # @option parameters [Boolean] :multipart whether request is multi-part
      # @option parameters [Boolean] :require_secure whether the request is expected to access sensitive data
      # @option parameters The rest options are treated as request parameters
      def initialize(resource_path, parameters = {})
        super

        if @require_secure && !secure?
          raise 'Secure connection required. Please provide your OAuth credentials via' \
                  ' :access_token and :access_secret in the parameters'
        end

        @resources = get_resources(@passed_resources)
        @parameters.merge!(api_key_params)
      end
      attr_reader :resources,
                  :multipart_request

      def get
        client.get(endpoint_url)
      end

      def post
        if multipart?
          client.post_multipart(endpoint_url(include_query: false), @parameters)
        else
          client.post(endpoint_url)
        end
      end

      def put
        client.put(endpoint_url(include_query: false), query)
      end

      def delete
        client.delete(endpoint_url)
      end

      def client # :nodoc:
        @client ||= secure? ? secure_client : basic_client
      end

      def query # :nodoc:
        to_url(parameters.merge(includes: resources.to_a.map { |r| association(r) }))
      end

      def to_url(val)
        if val.is_a? Array
          to_url(val.join(','))
        elsif val.is_a? Hash
          val.reject { |k, v|
            k.nil? || v.nil? || (k.respond_to?(:empty?) && k.empty?) || (v.respond_to?(:empty?) && v.empty?)
          }.map { |k, v| "#{to_url(k.to_s)}=#{to_url(v)}" }.join('&')
        else
          URI::DEFAULT_PARSER.escape(val.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        end
      end

      def association(options={}) # :nodoc:
        s = options[:resource].dup

        if options.include? :fields
          s << "(#{[options[:fields]].flatten.join(',')})"
        end

        if options.include?(:limit) || options.include?(:offset)
          s << ":#{options.fetch(:limit, 25)}:#{options.fetch(:offset, 0)}"
        end

        s
      end

      def endpoint_url(options = {}) # :nodoc:
        url = "#{base_path}#{resource_path}"
        url += "?#{query}" if options.fetch(:include_query, true)
        url
      end

      def multipart?
        !!multipart_request
      end

      private

      def secure_client
        SecureClient.new(access_token: token, access_secret: secret)
      end

      def basic_client
        BasicClient.new
      end

      def secure?
        !token.nil? && !secret.nil?
      end

      def get_resources(resources_param)
        if resources_param.class == String
          resources_param.split(',').map { |r| { resource: r } }
        elsif resources_param.class == Array
          resources_param.map do |r|
            if r.class == String
              { resource: r }
            else
              r
            end
          end
        end
      end

      def api_key_params
        return {} if secure?

        { api_key: Etsy.api_key }
      end
    end
  end
end
