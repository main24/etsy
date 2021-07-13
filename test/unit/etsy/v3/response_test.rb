require File.expand_path('../../../../test_helper', __FILE__)

module Etsy
  module V3
    class ResponseTest < Test::Unit::TestCase
      context 'An instance of the Response class' do
        context 'when an array is returned' do
          should 'returns the paginated response' do
            response_options = {
              method: :get,
              url: 'https://openapi.etsy.com/v3/application/shops/100/listings?status=active',
              status: 200,
              reason_phrase: 'OK',
              response_body: raw_json_fixture_data('v3/response/active_listings.json')
            }

            response = V3::Response.new(Faraday::Response.new(response_options))

            response.success?.should == true
            response.code.should     == 200
            response.body.should     == response_options[:response_body]
            response.result.should   == JSON.parse(response.body)['results']

            response.total.should      == 3 # total number of records in 'count'
            response.count.should      == 2 # number of records returned
            response.paginated?.should == true
          end
        end

        context 'when a single entity is returned' do
          should 'returns the paginated response' do
            response_options = {
              method: :get,
              url: 'https://openapi.etsy.com/v3/application/listings/10',
              status: 200,
              reason_phrase: 'OK',
              response_body: raw_json_fixture_data('v3/response/single_listing.json')
            }

            response = V3::Response.new(Faraday::Response.new(response_options))

            response.success?.should == true
            response.code.should     == 200
            response.body.should     == response_options[:response_body]
            response.result.should   == JSON.parse(response.body)

            response.total.should      == nil
            response.count.should      == 1
            response.paginated?.should == false

          end
        end

        context 'when exception returned' do
          context 'when code is 500' do
            should 'raise a ServerError exception' do
              response_options = {
                method: :get,
                url: 'https://openapi.etsy.com/v3/application/listings/10',
                status: 500,
                reason_phrase: 'Internal Server Error',
                response_body: { 'error' => 'The server encountered error' }.to_json
              }

              Etsy.silent_errors = false
              response = V3::Response.new(Faraday::Response.new(response_options))

              response.success?.should == false
              response.code.should     == 500
              response.body.should     == response_options[:response_body]

              exception = assert_raises(Etsy::ServerError) { response.result }
              exception.code.should == 500
              exception.data.should == 'The server encountered error'
            end
          end

          context 'when code is 502 and exception message says that it is temporary server error' do
            should 'raise a TemporaryServerError exception' do
              response_options = {
                method: :get,
                url: 'https://openapi.etsy.com/v3/application/listings/10',
                status: 502,
                reason_phrase: 'Bad Gateway',
                response_body: "<html><head><meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\"><title>502 Server Error</title></head><body text=#000000 bgcolor=#ffffff><h1>Error: Server Error</h1><h2>The server encountered a temporary error and could not complete your request.<p>Please try again in 30 seconds.</h2><h2></h2></body></html>"
              }

              Etsy.silent_errors = false
              response = V3::Response.new(Faraday::Response.new(response_options))

              response.success?.should == false
              response.code.should     == 502
              response.body.should     == response_options[:response_body]

              exception = assert_raises(Etsy::TemporaryServerError) { response.result }
              exception.code.should == 502
              exception.data.should == response_options[:response_body]
            end
          end

          context 'when code is 409' do
            context 'when the body states that resource is busy' do
              should 'raise a ResourceIsBusy exception' do
                response_options = {
                  method: :get,
                  url: 'https://openapi.etsy.com/v3/application/listings/10',
                  status: 409,
                  reason_phrase: 'Conflict',
                  response_body: { 'error' => 'The resource is being edited by another process. Please try again in a few moments.' }.to_json
                }

                Etsy.silent_errors = false
                response = V3::Response.new(Faraday::Response.new(response_options))

                response.success?.should == false
                response.code.should     == 409
                response.body.should     == response_options[:response_body]

                exception = assert_raises(Etsy::ResourceIsBusy) { response.result }
                exception.code.should == 409
                exception.data.should == 'The resource is being edited by another process. Please try again in a few moments.'
              end
            end
          end

          context 'when code is 400' do
            context 'when body says that all quantities are zero' do
              should 'raise a AllQuantitiesAreZero exception' do
                response_options = {
                  method: :get,
                  url: 'https://openapi.etsy.com/v3/application/listings/10',
                  status: 400,
                  reason_phrase: 'Bad Request',
                  response_body: { 'error' => 'All quantities are zero' }.to_json
                }

                Etsy.silent_errors = false
                response = V3::Response.new(Faraday::Response.new(response_options))

                response.success?.should == false
                response.code.should     == 400
                response.body.should     == response_options[:response_body]

                exception = assert_raises(Etsy::AllQuantitiesAreZero) { response.result }
                exception.code.should == 400
                exception.data.should == 'All quantities are zero'
              end
            end

            context 'when body says that the shop with provided shop_id does not exist' do
              should 'raise a ShopNotFound exception' do
                response_options = {
                  method: :get,
                  url: 'https://openapi.etsy.com/v3/application/listings/10',
                  status: 400,
                  reason_phrase: 'Bad Request',
                  response_body: { 'error' => 'Cannot update Shop because no Shop for shop_id XXXXX' }.to_json
                }

                Etsy.silent_errors = false
                response = V3::Response.new(Faraday::Response.new(response_options))

                response.success?.should == false
                response.code.should     == 400
                response.body.should     == response_options[:response_body]

                exception = assert_raises(Etsy::ShopNotFound) { response.result }
                exception.code.should == 400
                exception.data.should == 'Cannot update Shop because no Shop for shop_id XXXXX'
              end
            end

            context 'when body says that request cannot be recognized' do
              should 'raise a RequestCannotBeRecognized exception' do
                response_options = {
                  method: :get,
                  url: 'https://openapi.etsy.com/v3/application/listings/10',
                  status: 400,
                  reason_phrase: 'Bad Request',
                  response_body: '<HTML><HEAD> <TITLE>Bad Request</TITLE> </HEAD><BODY> <H1>Bad Request</H1> Your browser sent a request that this server could not understand.<P> Reference&#32;&#35;7&#46;87d408d1&#46;1528770128&#46;0 </BODY> </HTML>'
                }

                Etsy.silent_errors = false
                response = V3::Response.new(Faraday::Response.new(response_options))

                response.success?.should == false
                response.code.should     == 400
                response.body.should     == response_options[:response_body]

                exception = assert_raises(Etsy::RequestCannotBeRecognized) { response.result }
                exception.code.should == 400
                exception.data.should == response_options[:response_body]
              end
            end
          end

          context 'when code is 414' do
            context 'when body states that URI too long' do
              should 'raise a UriTooLong exception' do
                response_options = {
                  method: :get,
                  url: 'https://openapi.etsy.com/v3/application/listings/10',
                  status: 414,
                  reason_phrase: 'URI Too Long',
                  response_body: 'Error: URI Too Long'
                }

                Etsy.silent_errors = false
                response = V3::Response.new(Faraday::Response.new(response_options))

                response.success?.should == false
                response.code.should     == 414
                response.body.should     == response_options[:response_body]

                exception = assert_raises(Etsy::UriTooLong) { response.result }
                exception.code.should == 414
                exception.data.should == response_options[:response_body]
              end
            end
          end

          context 'when code is 503' do
            context 'when body states that operation is in progress' do
              should 'raise a OperationInProgress exception' do
                response_options = {
                  method: :get,
                  url: 'https://openapi.etsy.com/v3/application/listings/10',
                  status: 503,
                  reason_phrase: 'Service Unavailable',
                  response_body: "<?xml version=\"1.0\" encoding=\"utf-8\"?> <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\"> <html> <head> <title>503 Operation now in progress</title> </head> <body> <h1>Error 503 Operation now in progress</h1> <p>Operation now in progress</p> <h3>Guru Mediation:</h3> <p>Details: cache-iad2150-IAD 1528653727 3234964384</p> <hr> <p>Varnish cache server</p> </body> </html>"
                }

                Etsy.silent_errors = false
                response = V3::Response.new(Faraday::Response.new(response_options))

                response.success?.should == false
                response.code.should     == 503
                response.body.should     == response_options[:response_body]

                exception = assert_raises(Etsy::OperationInProgress) { response.result }
                exception.code.should == 503
                exception.data.should == response_options[:response_body]
              end
            end
          end

          context 'when code is 429' do
            should 'raise a ExceededOverallRateLimit exception' do
              puts("Pending: #{self.method_name}")
            end
          end

          context 'when response is unknown' do
            should 'raise an invalid JSON exception' do
              response_options = {
                method: :get,
                url: 'https://openapi.etsy.com/v3/application/listings/10',
                status: 515,
                reason_phrase: 'Service Unavailable',
                response_body: 'Random text'
              }

              Etsy.silent_errors = false
              response = V3::Response.new(Faraday::Response.new(response_options))

              response.success?.should == false
              response.code.should     == 515
              response.body.should     == response_options[:response_body]

              exception = assert_raises(Etsy::EtsyJSONInvalid) { response.result }
              exception.code.should == 515
              exception.data.should == response_options[:response_body]
            end
          end
        end
      end
    end
  end
end
