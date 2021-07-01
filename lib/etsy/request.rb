require 'forwardable'

module Etsy

  # = Request
  #
  # A basic wrapper around GET requests to the Etsy JSON API
  #
  class Request
    extend Forwardable

    class << self
      # Perform a GET request for the resource with optional parameters - returns
      # A Response object with the payload data
      def get(resource_path, parameters = {})
        request = Request.new(resource_path, parameters)
        Response.new(request.get)
      end

      def post(resource_path, parameters = {})
        request = Request.new(resource_path, parameters)
        Response.new(request.post)
      end

      def put(resource_path, parameters = {})
        request = Request.new(resource_path, parameters)
        Response.new(request.put)
      end

      def delete(resource_path, parameters = {})
        request = Request.new(resource_path, parameters)
        Response.new(request.delete)
      end
    end

    API_VERSIONS = [
      (API_VERSION_2 = 'v2'),
      (API_VERSION_3 = 'v3')
    ].freeze
    DEFAULT_API_VERSION = API_VERSION_2

    # Create a new request for the resource with optional parameters
    def initialize(resource_path, parameters = {})
      initialize_request_object(resource_path, parameters)
    end
    attr_reader :request_object

    def_delegators :@request_object,
                   :get,
                   :base_path,
                   :post,
                   :put,
                   :delete,
                   :client,
                   :query,
                   :to_url,
                   :association,
                   :endpoint_url,
                   :multipart?,
                   :token,
                   :secret,
                   :multipart_request,
                   :resource_path,
                   :resources,
                   :parameters

    private

    def initialize_request_object(resource_path, parameters)
      api_version = get_api_version(parameters.delete(:api_version))

      @request_object ||=
        api_version == API_VERSION_2 ?
          Etsy::V2::Request.new(resource_path, parameters) :
          Etsy::V3::Request.new(resource_path, parameters)
    end

    def get_api_version(passed_api_version)
      if passed_api_version.nil? || !API_VERSIONS.include?(passed_api_version)
        DEFAULT_API_VERSION
      else
        passed_api_version
      end
    end
  end
end
