module Etsy
  class Response
    class << self
      def call(raw_response, api_version: Etsy::Request::API_VERSION_2)
        api_version == Etsy::Request::API_VERSION_2 ?
          Etsy::V2::Response.new(raw_response) :
          Etsy::V3::Response.new(raw_response)
      end
    end
  end
end
