require File.expand_path('../../../test_helper', __FILE__)

module Etsy
  class ResponseTest < Test::Unit::TestCase

    context "An instance of the Response class" do
      
      should "be able to return the total" do
        r = Response.new(stub(:body => '{ "count": 42 }'))
        
        r.total.should == 42
      end

      should "be able to decode the JSON data to a hash" do
        data = '{ "foo":"bar" }'

        r = Response.new(stub(:body => data))
        r.to_hash.should == {'foo' => 'bar'}
      end

      should "only decode the JSON data once" do
        JSON.expects(:parse).once.returns({})

        r = Response.new(stub(:body => '{ "foo":"bar" }'))
        2.times { r.to_hash }
      end

      should "have a record count when the response is not paginated" do
        raw_response = mock
        raw_response.stubs(:body => '{ "count": 1 }')
        r = Response.new(raw_response)

        r.count.should == 1
      end

      should "have a record count when the response is paginated" do
        raw_response = mock
        raw_response.stubs(:body => '{ "count": 100, "results": [{},{}], "pagination": {} }')
        r = Response.new(raw_response)

        r.count.should == 2
      end

      should "return a count of 0 when the response is paginated and the results are empty" do
        raw_response = mock
        raw_response.stubs(:body => '{ "count": 100, "results": null, "pagination": {} }')
        r = Response.new(raw_response)

        r.count.should == 0
      end

      should "return an array if there are multiple results entries" do
        r = Response.new('')
        r.expects(:code).with().returns('200')
        r.expects(:count).with().returns(2)
        r.expects(:to_hash).with().returns('results' => %w(one two))

        r.result.should == %w(one two)
      end

      should "return a single value for results if there is only 1 result" do
        r = Response.new('')
        r.expects(:code).with().returns('200')
        r.expects(:count).with().returns(1)
        r.expects(:to_hash).with().returns('results' => ['foo'])

        r.result.should == 'foo'
      end

      should "provide the complete raw body" do
        raw_response = mock
        raw_response.stubs(:body => "I am not JSON")
        r = Response.new(raw_response)

        r.body.should == 'I am not JSON'
      end

      context 'when response is not json' do
        context 'when code is 500' do
          should "raise a ServerError exception" do
            raw_response = mock
            raw_response.stubs(body: "Server Error", code: 500)
            r = Response.new(raw_response)

            exception = assert_raises(Etsy::ServerError) { r.to_hash }
            assert_equal( 500, exception.code )
            assert_equal( "Server Error", exception.data )
          end
        end

        context 'when code is 409' do
          context 'when the body states that resource is busy' do
            should "raise a ResourceIsBusy exception" do
              raw_response = mock
              raw_response.stubs(body: "The resource is being edited by another process. Please try again in a few moments.", code: 409)
              r = Response.new(raw_response)

              exception = assert_raises(Etsy::ResourceIsBusy) { r.to_hash }
              assert_equal(409, exception.code)
              assert_equal("The resource is being edited by another process. Please try again in a few moments.", exception.data)
            end
          end
        end

        context 'when code is 400' do
          context 'when body says that all quantities are zero' do
            should "raise a AllQuantitiesAreZero exception" do
              raw_response = mock
              raw_response.stubs(body: "_object: All quantities are zero", code: 400)
              r = Response.new(raw_response)

              exception = assert_raises(Etsy::AllQuantitiesAreZero) { r.to_hash }
              assert_equal(400, exception.code)
              assert_equal("_object: All quantities are zero", exception.data)
            end
          end

          context 'when body says that request cannot be recognized' do
            should "raise a RequestCannotBeRecognized exception" do
              raw_response = mock
              raw_response.stubs(
                body: "<HTML><HEAD> <TITLE>Bad Request</TITLE> </HEAD><BODY> <H1>Bad Request</H1> Your browser sent a request that this server could not understand.<P> Reference&#32;&#35;7&#46;87d408d1&#46;1528770128&#46;0 </BODY> </HTML>",
                code: 400
              )
              r = Response.new(raw_response)

              exception = assert_raises(Etsy::RequestCannotBeRecognized) { r.to_hash }
              assert_equal(400, exception.code)
              assert_equal(
                "<HTML><HEAD> <TITLE>Bad Request</TITLE> </HEAD><BODY> <H1>Bad Request</H1> Your browser sent a request that this server could not understand.<P> Reference&#32;&#35;7&#46;87d408d1&#46;1528770128&#46;0 </BODY> </HTML>",
                exception.data
              )
            end
          end
        end

        context 'when code is 414' do
          context 'when body states that URI too long' do
            should "raise a UriTooLong exception" do
              raw_response = mock
              raw_response.stubs(body: "Error: URI Too Long", code: 414)
              r = Response.new(raw_response)

              exception = assert_raises(Etsy::UriTooLong) { r.to_hash }
              assert_equal(414, exception.code)
              assert_equal("Error: URI Too Long", exception.data)
            end
          end
        end

        context 'when code is 503' do
          context 'when body states that operation is in progress' do
            should "raise a OperationInProgress exception" do
              raw_response = mock
              raw_response.stubs(
                body: "<?xml version=\"1.0\" encoding=\"utf-8\"?> <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\"> <html> <head> <title>503 Operation now in progress</title> </head> <body> <h1>Error 503 Operation now in progress</h1> <p>Operation now in progress</p> <h3>Guru Mediation:</h3> <p>Details: cache-iad2150-IAD 1528653727 3234964384</p> <hr> <p>Varnish cache server</p> </body> </html>",
                code: 503
              )
              r = Response.new(raw_response)

              exception = assert_raises(Etsy::OperationInProgress) { r.to_hash }
              assert_equal(503, exception.code)
              assert_equal(
                "<?xml version=\"1.0\" encoding=\"utf-8\"?> <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\"> <html> <head> <title>503 Operation now in progress</title> </head> <body> <h1>Error 503 Operation now in progress</h1> <p>Operation now in progress</p> <h3>Guru Mediation:</h3> <p>Details: cache-iad2150-IAD 1528653727 3234964384</p> <hr> <p>Varnish cache server</p> </body> </html>",
                exception.data
              )
            end
          end
        end

        context 'when response is unknown' do
          should "raise an invalid JSON exception" do
            raw_response = mock
            raw_response.stubs(body: "I am not JSON", code: 515)
            r = Response.new(raw_response)

            exception = assert_raises(Etsy::EtsyJSONInvalid) { r.to_hash }
            assert_equal(515, exception.code)
            assert_equal("I am not JSON", exception.data)
          end
        end
      end

      should "raise OAuthTokenRevoked" do
        raw_response = mock
        raw_response.stubs(:body => "oauth_problem=token_revoked")
        r = Response.new(raw_response)

        lambda { r.to_hash }.should raise_error(Etsy::OAuthTokenRevoked)
      end

      should "raise MissingShopID" do
        raw_response = mock
        raw_response.stubs(:body => "something Shop with PK shop_id something")
        r = Response.new(raw_response)

        lambda { r.to_hash }.should raise_error(Etsy::MissingShopID)
      end

      should "raise InvalidUserID" do
        raw_response = mock
        raw_response.stubs(:body => "'someguy' is not a valid user_id")
        r = Response.new(raw_response)

        lambda { r.to_hash }.should raise_error(Etsy::InvalidUserID)
      end

      should "raise TemporaryIssue" do
        raw_response = mock
        raw_response.stubs(:body => "something Temporary Etsy issue something")
        r = Response.new(raw_response)

        lambda { r.to_hash }.should raise_error(Etsy::TemporaryIssue)
      end

      should "raise ResourceUnavailable" do
        raw_response = mock
        raw_response.stubs(:body => "something Resource temporarily unavailable something")
        r = Response.new(raw_response)

        lambda { r.to_hash }.should raise_error(Etsy::ResourceUnavailable)
      end

      should "raise ExceededRateLimit" do
        raw_response = mock
        raw_response.stubs(:body => "something You have exceeded your API limit something")
        r = Response.new(raw_response)

        lambda { r.to_hash }.should raise_error(Etsy::ExceededRateLimit)
      end

      should "provide the code" do
        raw_response = mock
        raw_response.expects(:code => "400")
        r = Response.new(raw_response)

        r.code.should == '400'
      end

      should "consider a code of 2xx successful" do
        raw_response = mock

        raw_response.expects(:code => "200")
        r = Response.new(raw_response)
        r.should be_success

        raw_response.expects(:code => "201")
        r = Response.new(raw_response)
        r.should be_success
      end

      should "consider a code of 4xx unsuccessful" do
        raw_response = mock

        raw_response.expects(:code => "404")
        r = Response.new(raw_response)
        r.should_not be_success
      end

      should "consider a code of 5xx unsuccessful" do
        raw_response = mock

        raw_response.expects(:code => "500")
        r = Response.new(raw_response)
        r.should_not be_success
      end
    end


  end
end
