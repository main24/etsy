require File.expand_path('../../../../test_helper', __FILE__)

module Etsy
  module V3
    class RequestTest < Test::Unit::TestCase
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
            Etsy::V3::Request.new(
              '/path',
              v3_request_params
                .merge(v2_request_params)
            )

          request.parameters.should == v3_request_params.merge(v2_request_params.slice(:includes))
        end
      end

      context 'when passed credentials' do
        should 'build oauth client with correct settings' do
          with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
            request =
              Etsy::V3::Request.new(
                '/path',
                { access_token: 'client_token' }
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
          should 'call \'get\' of the oauth token object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings',
                {
                  access_token: 'client_token',
                  state: 'active'
                }
              ]

              request        = Etsy::V3::Request.new(*params)
              client         = request.client
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
          should 'call \'put\' of the oauth token object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings/1',
                {
                  access_token: 'client_token',
                  description: 'updated description'
                }
              ]

              request        = Etsy::V3::Request.new(*params)
              client         = request.client
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
          should 'call \'post\' of the oauth token object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings',
                {
                  access_token: 'client_token',
                  title: 'new listing',
                  description: 'new description'
                }
              ]

              request        = Etsy::V3::Request.new(*params)
              client         = request.client
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
          should 'call \'delete\' of the oauth token object' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X') do
              params = [
                '/shops/1/listings/1',
                { access_token: 'client_token' }
              ]

              request        = Etsy::V3::Request.new(*params)
              client         = request.client
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

        context 'User agent options' do
          context 'when user agent is defined per application' do
            should 'set up the client with user agent' do
              with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X', user_agent: 'TestApp') do
                request =
                  Etsy::V3::Request.new(
                    '/path',
                    { access_token: 'client_token' }
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
                  Etsy::V3::Request.new(
                    '/path',
                    {
                      access_token: 'client_token',
                      oauth_client_options: {
                        connection_opts: { headers: { 'User-Agent' => 'one-off-user-agent' } }
                      }
                    }
                  )

                request.client.client.options[:connection_opts].should ==
                  { headers: { 'User-Agent' => 'one-off-user-agent' } }
              end
            end
          end
        end

        context 'oauth client options' do
          should 'have default options' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X', user_agent: 'TestApp') do
              expected_options = {
                token_url: '/oauth/token',
                authorize_url: '/oauth/authorize',
                max_redirects: 5,
                token_method: :post,
                raise_errors: false,
                connection_opts: { headers: { 'User-Agent' => 'TestApp' } }
              }

              request =
                Etsy::V3::Request.new(
                  '/path',
                  {
                    access_token: 'client_token'
                  }
                )

              request.client.client.options
                .slice(:token_url, :authorize_url, :max_redirects, :token_method, :raise_errors, :connection_opts)
                .should == expected_options

              request.client.client.site.should == 'https://openapi.etsy.com/v3/application'
            end
          end

          should 'be re-defined via oauth_client_options' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X', user_agent: 'TestApp') do
              expected_options = {
                token_url: '/v3/oauth',
                authorize_url: '/v3/authorize',
                max_redirects: 1,
                token_method: :get,
                raise_errors: true,
                site: 'https://yet-another-site.com',
                connection_opts: { headers: { 'User-Agent' => 'one-off-user-agent' } }
              }

              request =
                Etsy::V3::Request.new(
                  '/path',
                  {
                    access_token: 'client_token',
                    oauth_client_options: expected_options
                  }
                )

              request.client.client.options
                .slice(:token_url, :authorize_url, :max_redirects, :token_method, :raise_errors, :connection_opts)
                .should == expected_options.except(:site)

              request.client.client.site.should == expected_options.fetch(:site)
            end
          end
        end

        context 'oauth token options' do
          should 'be re-defined via oauth_token_options' do
            with_etsy_app_keys(api_key: 'api_key_X', api_secret: 'api_secret_X', user_agent: 'TestApp') do
              expected_options = {
                refresh_token: 'defined_refresh_token',
                expires_in: 3600,
                mode: :body,
                param_name: 'oauth_token'
              }

              request =
                Etsy::V3::Request.new(
                  '/path',
                  {
                    access_token: 'client_token',
                    oauth_token_options: expected_options
                  }
                )

              request.client.expires_in.should    == expected_options.fetch(:expires_in)
              request.client.refresh_token.should == expected_options.fetch(:refresh_token)
              request.client.options.should       ==
                { mode: expected_options.fetch(:mode), header_format: "Bearer %s", param_name: expected_options.fetch(:param_name) }
            end
          end
        end
      end
    end
  end
end
