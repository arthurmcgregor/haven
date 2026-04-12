require 'test_helper'

class OidcAuthTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
      provider: 'openid_connect',
      uid: 'integration-test-uid',
      info: {
        email: 'oidcintegration@example.com',
        name: 'Integration User',
        preferred_username: 'integrationuser'
      }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:openid_connect] = nil
  end

  test "successful first OIDC login creates user and signs in" do
    assert_difference 'User.count', 1 do
      post '/users/auth/openid_connect/callback'
    end

    user = User.find_by(uid: 'integration-test-uid')
    assert_not_nil user
    assert_equal 'oidcintegration@example.com', user.email
    assert_equal 'Integration User', user.name
    assert_equal 0, user.admin
    assert_equal 'openid_connect', user.provider
    assert user.basic_auth_username.present?
    assert user.basic_auth_password.present?
    assert user.image_password.present?
    assert_response :redirect
  end

  test "returning OIDC user signs in without creating duplicate" do
    post '/users/auth/openid_connect/callback'
    delete destroy_user_session_path

    assert_no_difference 'User.count' do
      post '/users/auth/openid_connect/callback'
    end

    assert_response :redirect
  end

  test "failed OIDC auth redirects to login with error" do
    OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials

    get '/users/auth/openid_connect/callback'
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_match(/failed/i, flash[:alert])
  end
end
