ENV['RAILS_ENV'] ||= 'test'
ENV['HAVEN_OIDC_ISSUER'] ||= 'https://test-issuer.example.com'
ENV['HAVEN_OIDC_CLIENT_ID'] ||= 'test-client-id'
ENV['HAVEN_OIDC_CLIENT_SECRET'] ||= 'test-client-secret'
ENV['HAVEN_OIDC_REDIRECT_URI'] ||= 'http://localhost:3000/users/auth/openid_connect/callback'
require_relative '../config/environment'
require 'rails/test_help'

OmniAuth.config.test_mode = true

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
