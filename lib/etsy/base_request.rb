module Etsy
  class BaseRequest
    # @param [String] resource_path path to the API resource, i.e. '/shops/1/listings'
    # @param [Hash] parameters the options to initialize OAuth client and request params
    # @option parameters [String] :access_token token client id of the user
    # @option parameters [Hash] :oauth_client_options options for initialization of OAuth2::Client
    # @option parameters [Hash] :oauth_token_options options for initialization of OAuth2::AccessToken
    def initialize(resource_path, parameters = {})
      original_params = parameters.dup

      @token  = original_params.delete(:access_token) || Etsy.credentials[:access_token]
      @secret = original_params.delete(:access_secret) || Etsy.credentials[:access_secret]

      @require_secure       = original_params.delete(:require_secure)
      @passed_resources     = original_params.delete(:includes)

      @multipart_request    = original_params.delete(:multipart)
      @resource_path        = resource_path
      @oauth_client_options = original_params.delete(:oauth_client_options) || {}
      @oauth_token_options  = original_params.delete(:oauth_token_options) || {}
      @parameters           = original_params
    end
    attr_reader :token,
                :secret,
                :resource_path,
                :parameters

    def base_path
      self.class::BASE_PATH
    end

    def get
      raise NotImplementedError
    end

    def post
      raise NotImplementedError
    end

    def put
      raise NotImplementedError
    end

    def delete
      raise NotImplementedError
    end
  end
end
