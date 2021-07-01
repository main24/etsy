require File.expand_path('../../../test_helper', __FILE__)

module Etsy
  class RequestWrapperTest < Test::Unit::TestCase
    def default_v3_params
      { api_version: 'v3' }
    end

    context 'when requested v3 version' do
      context 'when initialized via wrapper object' do
        should 'initialize V3::Request object' do
          request = Etsy::Request.new('/path', default_v3_params)

          request.request_object.class.should == Etsy::V3::Request
          request.request_object.client.class.should == OAuth2::AccessToken
          request.request_object.client.client.class.should == OAuth2::Client
          request.client.should == request.request_object.client
        end

        context 'when v2 params passed for initialization' do
          should 'strip them from parameters' do
            v3_request_params = {
              state: 'active'
            }

            v2_request_params = {
              includes: ['Inventory', 'Images'],
              multipart: true,
              require_secure: true,
              fields: ['id']
            }

            request =
              Etsy::Request.new(
                '/path',
                default_v3_params
                  .merge(v3_request_params)
                  .merge(v2_request_params)
              )

            request.request_object.parameters.should == v3_request_params
          end
        end
      end

      context 'when passed credentials' do
        should 'build oauth client with correct settings' do
          with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
            request =
              Etsy::Request.new(
                '/path',
                default_v3_params.merge(access_token: 'client_token')
              )

            request.client.client.id.should     == 'api_key_X'
            request.client.client.secret.should == 'api_secret_X'
            request.client.client.site.should   == 'https://openapi.etsy.com/v3/application'
            request.client.token.should         == 'client_token'
            request.client.options.should       ==
              { mode: :header, header_format: "Bearer %s", param_name: 'access_token' }
          end
        end
      end

      context 'API requests' do
        context 'when \'get\' requested' do
          should 'call \'get\' of the client object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings',
                default_v3_params.merge(
                  access_token: 'client_token',
                  state: 'active'
                )
              ]

              request        = Etsy::Request.new(*params)
              client         = request.request_object.client
              oauth_response = stub()
              response       = stub()

              oauth_response
                .stubs(:response)
                .returns(response)

              client
                .expects(:get)
                .with('shops/1/listings', params: { state: 'active' }, headers: { 'x-api-key' => 'api_key_X' })
                .returns(oauth_response)

              request.get.should == response
            end
          end
        end

        context 'when \'put\' requested' do
          should 'call \'put\' of the client object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings/1',
                default_v3_params.merge(
                  access_token: 'client_token',
                  description: 'updated description'
                )
              ]

              request        = Etsy::Request.new(*params)
              client         = request.request_object.client
              oauth_response = stub()
              response       = stub()

              oauth_response
                .stubs(:response)
                .returns(response)

              client
                .expects(:put)
                .with(
                  'shops/1/listings/1',
                  body: { description: 'updated description' },
                  headers: { 'x-api-key' => 'api_key_X' }
                )
                .returns(oauth_response)

              request.put.should == response
            end
          end
        end

        context 'when \'post\' requested' do
          should 'call \'post\' of the client object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings',
                default_v3_params.merge(
                  access_token: 'client_token',
                  title: 'new listing',
                  description: 'new description'
                )
              ]

              request        = Etsy::Request.new(*params)
              client         = request.request_object.client
              oauth_response = stub()
              response       = stub()

              oauth_response
                .stubs(:response)
                .returns(response)

              client
                .expects(:post)
                .with(
                  'shops/1/listings',
                  body: { title: 'new listing', description: 'new description' },
                  headers: { 'x-api-key' => 'api_key_X' }
                )
                .returns(oauth_response)

              request.post.should == response
            end
          end
        end

        context 'when \'delete\' requested' do
          should 'call \'delete\' of the client object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings/1',
                default_v3_params.merge(access_token: 'client_token')
              ]

              request        = Etsy::Request.new(*params)
              client         = request.request_object.client
              oauth_response = stub()
              response       = stub()

              oauth_response
                .stubs(:response)
                .returns(response)

              client
                .expects(:delete)
                .with(
                  'shops/1/listings/1',
                  headers: { 'x-api-key' => 'api_key_X' }
                )
                .returns(oauth_response)

              request.delete.should == response
            end
          end
        end

        context 'bypassing user agent options' do
          context 'when user agent is defined per application' do
            should 'set up the client with user agent' do
              with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X', user_agent: 'TestApp') do
                request =
                  Etsy::Request.new(
                    '/path',
                    default_v3_params.merge(access_token: 'client_token')
                  )

                request.client.client.options[:connection_opts].should ==
                  { headers: { 'User-Agent' => 'TestApp' } }
              end
            end
          end

          context 'when user agent is passed via connection_opts' do
            should 'redefine the user agent' do
              with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X', user_agent: 'TestApp') do
                request =
                  Etsy::Request.new(
                    '/path',
                    {
                      access_token: 'client_token',
                      oauth_client_options: {
                        connection_opts: { headers: { 'User-Agent' => 'one-off-user-agent' } }
                      }
                    }.merge(default_v3_params)
                  )

                request.client.client.options[:connection_opts].should ==
                  { headers: { 'User-Agent' => 'one-off-user-agent' } }
              end
            end
          end
        end

        context 'Passing oauth token and client options' do
          should 'be bypassed to V3::Request' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X', user_agent: 'TestApp') do
              oauth_client_options = {
                token_url: '/v3/oauth',
                connection_opts: { headers: { 'User-Agent' => 'one-off-user-agent' } }
              }

              oauth_token_options = {
                refresh_token: 'defined_refresh_token',
                expires_in: 3600,
              }

              request =
                Etsy::Request.new(
                  '/path',
                  {
                    access_token: 'client_token',
                    oauth_client_options: oauth_client_options,
                    oauth_token_options: oauth_token_options
                  }.merge(default_v3_params)
                )

              request.client.client.options
                .slice(:token_url, :connection_opts)
                .should == oauth_client_options

              request.client.expires_in.should    == oauth_token_options.fetch(:expires_in)
              request.client.refresh_token.should == oauth_token_options.fetch(:refresh_token)
            end
          end
        end
      end
    end
  end
end
