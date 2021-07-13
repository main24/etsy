require File.expand_path('../../../test_helper', __FILE__)

module Etsy
  class ResponseTest < Test::Unit::TestCase
    context 'when version is not specified' do
      should 'return an instance of V2::Response' do
        raw_response = stub(body: '{ "count": 42 }', code: 200)
        response     = Response.call(raw_response)

        response.class.should == V2::Response
        response.raw_response == raw_response
      end
    end

    context 'when requested v2 version' do
      should 'return an instance of V2::Response' do
        raw_response = stub(body: '{ "count": 42 }', code: 200)
        response     = Response.call(raw_response, api_version: 'v2')

        response.class.should == V2::Response
        response.raw_response == raw_response
      end
    end

    context 'when requested v3 version' do
      should 'return an instance of V3::Response' do
        raw_response = stub(body: '{ "count": 42 }', status: 200)
        response     = Response.call(raw_response, api_version: 'v3')

        response.class.should == V3::Response
        response.raw_response == raw_response
      end
    end
  end
end
