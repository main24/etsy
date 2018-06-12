module Etsy
  class BaseEtsyException < StandardError; end
  class OAuthTokenRevoked < BaseEtsyException; end
  class MissingShopID < BaseEtsyException; end
  class TemporaryIssue < BaseEtsyException; end
  class ResourceUnavailable < TemporaryIssue; end
  class ExceededRateLimit < TemporaryIssue; end
  class InvalidUserID < BaseEtsyException; end
  class EtsyJSONInvalid < BaseEtsyException
    attr_reader :code, :data
    def initialize(args)
      @code = args[:code]
      @data = args[:data]
    end
  end

  class ServerError < EtsyJSONInvalid; end
  class ResourceIsBusy < EtsyJSONInvalid; end
  class AllQuantitiesAreZero < EtsyJSONInvalid; end
  class RequestCannotBeRecognized < EtsyJSONInvalid; end
  class UriTooLong < EtsyJSONInvalid; end
  class OperationInProgress < EtsyJSONInvalid; end

  # = Response
  #
  # Basic wrapper around the Etsy JSON response data
  #
  class Response

    # Create a new response based on the raw HTTP response
    def initialize(raw_response)
      @raw_response = raw_response
    end

    # Convert the raw JSON data to a hash
    def to_hash
      validate!
      @hash ||= json
    end

    def body
      @raw_response.body
    end

    def code
      @raw_response.code
    end

    # Number of records in the response results
    def count
      if paginated?
        to_hash['results'].nil? ? 0 : to_hash['results'].size
      else
        to_hash['count']
      end
    end

    # Results of the API request
    def result
      if success?
        results = to_hash['results'] || []
        count == 1 ? results.first : results
      else
        Etsy.silent_errors ? [] : validate!
      end
    end

    # Total number of results of the request
    def total
      @total ||= to_hash['count']
    end

    def success?
      !!(code =~ /2\d\d/)
    end

    def paginated?
      !!to_hash['pagination']
    end

    private

    def data
      @raw_response.body
    end

    def json
      @hash ||= JSON.parse(data)
    end

    def validate!
      raise OAuthTokenRevoked         if token_revoked?
      raise MissingShopID             if missing_shop_id?
      raise InvalidUserID             if invalid_user_id?
      raise TemporaryIssue            if temporary_etsy_issue?
      raise ResourceUnavailable       if resource_unavailable?
      raise ExceededRateLimit         if exceeded_rate_limit?
      raise invalid_json_class.new({ code: code, data: data }) unless valid_json?

      true
    end

    def invalid_json_class
      return ServerError if server_error?
      return ResourceIsBusy if resource_is_busy?
      return AllQuantitiesAreZero if all_quantities_are_zero?
      return RequestCannotBeRecognized if request_cannot_be_recognized?
      return UriTooLong if uri_too_long?
      return OperationInProgress if operation_in_progress?
      EtsyJSONInvalid
    end

    def valid_json?
      json
      return true
    rescue JSON::ParserError
      return false
    end

    def server_error?
      #
      # code: 500,
      # body: Server Error
      #
      code.to_s == '500'
    end

    def resource_is_busy?
      #
      # code: 409,
      # body: The resource is being edited by another process. Please try again in a few moments.
      #
      code.to_s == '409' && body =~ /resource is being edited by another process/
    end

    def all_quantities_are_zero?
      #
      # code: 400,
      # body: _object: All quantities are zero
      #
      code.to_s == '400' && body =~ /all quantities are zero/i
    end

    def request_cannot_be_recognized?
      #
      # code: 400,
      # body: <HTML><HEAD> <TITLE>Bad Request</TITLE> </HEAD><BODY> <H1>Bad Request</H1> Your browser sent a request that this server could not understand.<P> Reference&#32;&#35;7&#46;87d408d1&#46;1528770128&#46;0 </BODY> </HTML>
      #
      body =~ /bad request/i
    end

    def uri_too_long?
      #
      # code: 414,
      # body: Error: URI Too Long
      #
      code.to_s == '414' && body =~ /URI Too Long/i
    end

    def operation_in_progress?
      #
      # code: 503
      # body: <?xml version="1.0" encoding="utf-8"?> <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"> <html> <head> <title>503 Operation now in progress</title> </head> <body> <h1>Error 503 Operation now in progress</h1> <p>Operation now in progress</p> <h3>Guru Mediation:</h3> <p>Details: cache-iad2150-IAD 1528653727 3234964384</p> <hr> <p>Varnish cache server</p> </body> </html>
      #
      code.to_s == '503' && body =~ /Operation now in progress/i
    end

    def token_revoked?
      data == "oauth_problem=token_revoked"
    end

    def missing_shop_id?
      data =~ /Shop with PK shop_id/
    end

    def invalid_user_id?
      data =~ /is not a valid user_id/
    end

    def temporary_etsy_issue?
      data =~ /Temporary Etsy issue/
    end

    def resource_unavailable?
      data =~ /Resource temporarily unavailable/
    end

    def exceeded_rate_limit?
      data =~ /You have exceeded/
    end
  end
end
