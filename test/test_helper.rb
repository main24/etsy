# http://sneaq.net/textmate-wtf
$:.reject! { |e| e.include? 'TextMate' }

require 'rubygems'
require 'active_support' # workaround load issue with shoulda in rubinius
require 'test/unit'
require 'shoulda'
require 'matchy'
require 'mocha/setup'
require 'cgi'

require File.expand_path('../../lib/etsy', __FILE__)

class Test::Unit::TestCase

  def raw_fixture_data(filename)
    file = File.dirname(__FILE__) + "/fixtures/#{filename}"
    File.read(file)
  end

  def read_fixture(filename)
    JSON.parse(raw_fixture_data(filename))['results']
  end

  def mock_request(endpoint, options, resource, file)
    objects       = []
    underscored_fixture_filename = "#{resource.gsub(/([^^])([A-Z])/, '\1_\2').downcase}/#{file}"
    response_data = raw_fixture_data(underscored_fixture_filename)

    Etsy::Request.stubs(:new).with(endpoint, options).returns(stub(:get => stub(:body => response_data, :code => '200')))

    JSON.parse(response_data)['results'].each_with_index do |result, index|
      object = "#{resource.downcase}_#{index}"
      if options[:access_token] && options[:access_secret]
        Etsy.const_get(resource).stubs(:new).with(result, options[:access_token], options[:access_secret]).returns(object)
      else
        Etsy.const_get(resource).stubs(:new).with(result).returns(object)
      end
      objects << object
    end

    objects
  end

  def with_etsy_app_keys(api_key:, api_secret:, user_agent: nil)
    original_api_key    = Etsy.api_key
    original_api_secret = Etsy.api_secret
    original_user_agent = Etsy.user_agent

    Etsy.api_key    = 'api_key_X'
    Etsy.api_secret = 'api_secret_X'
    Etsy.user_agent = user_agent || original_user_agent

    yield

    Etsy.api_key    = original_api_key
    Etsy.api_secret = original_api_secret
    Etsy.user_agent = original_user_agent
  end
end
