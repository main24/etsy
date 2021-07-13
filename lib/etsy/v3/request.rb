module Etsy
  module V3
    class Request < BaseRequest
      BASE_PATH = '/v3/application'.freeze

      # Initialize a V3::Request
      #
      # @param [String] resource_path path to the API resource, i.e. '/shops/1/listings'
      # @param [Hash] parameters the options to initialize OAuth client and request params
      # @option parameters [String] :access_token token client id of the user
      # @option parameters [Hash] :oauth_client_options options for initialization of OAuth2::Client
      # @option parameters [Hash] :oauth_token_options options for initialization of OAuth2::AccessToken
      # @option parameters The rest options are treated as request parameters
      def initialize(resource_path, parameters = {})
        super

        @parameters.delete(:fields) # V2 request parameter
      end
      attr_reader :oauth_client_options,
                  :oauth_token_options

      def get
        make_request(:get, resource_path, params: @parameters)
      end

      def put
        make_request(:put, resource_path, body: @parameters)
      end

      def post
        make_request(:post, resource_path, body: @parameters)
      end

      def delete
        make_request(:delete, resource_path)
      end

      def client
        @client ||= OAuth2::AccessToken.new(oauth_client, token, oauth_token_options)
      end

      private

      def default_oauth_client_options
        { raise_errors: false }
      end

      def oauth_client
        options = { site: "#{Etsy.protocol}://#{Etsy.host}/#{BASE_PATH.delete_prefix('/')}" }
        options.merge!(connection_opts: { headers: { 'User-Agent' => Etsy.user_agent } }) if Etsy.user_agent
        options.merge!(default_oauth_client_options.merge(oauth_client_options))

        OAuth2::Client.new(
          Etsy.api_key,
          Etsy.api_secret,
          options
        )
      end

      def make_request(verb, path, **params)
        client
          .send(verb, path.delete_prefix('/'), **(params || {}).merge(headers: api_key_header))
          .response
      end

      def api_key_header
        { 'x-api-key' => Etsy.api_key }
      end
    end
  end
end
