require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should not save a user without basic_auth credentials" do
    assert_raises ActiveRecord::RecordInvalid do
      User.create!(
        email: "alexander@hamilton.com",
        name: "Alexander Hamilton",
        password: "alexes password",
        admin: 0)
    end
  end

  test "should save a user with all data" do
    assert User.create!(
      email: "alexander@hamilton.com",
      password: "alexes password",
      admin: 0,
      basic_auth_username: "abcd",
      basic_auth_password: "efgh",
      image_password: "1234")
  end

  test "from_omniauth creates a new user" do
    auth = OmniAuth::AuthHash.new(
      provider: 'openid_connect',
      uid: 'new-oidc-uid-999',
      info: { email: 'newuser@example.com', name: 'New OIDC User', preferred_username: 'newuser' }
    )

    assert_difference 'User.count', 1 do
      user = User.from_omniauth(auth)
      assert user.persisted?
      assert_equal 'newuser@example.com', user.email
      assert_equal 'New OIDC User', user.name
      assert_equal 0, user.admin
      assert_equal 'openid_connect', user.provider
      assert_equal 'new-oidc-uid-999', user.uid
      assert user.basic_auth_username.present?
      assert user.basic_auth_password.present?
      assert user.image_password.present?
    end
  end

  test "from_omniauth returns existing user on second call" do
    auth = OmniAuth::AuthHash.new(
      provider: 'openid_connect',
      uid: 'oidc-sub-12345',
      info: { email: 'oidc@example.com', name: 'OIDC User' }
    )

    assert_no_difference 'User.count' do
      user = User.from_omniauth(auth)
      assert_equal users(:oidc_user).id, user.id
    end
  end

  test "from_omniauth falls back to preferred_username when name is nil" do
    auth = OmniAuth::AuthHash.new(
      provider: 'openid_connect',
      uid: 'fallback-name-uid',
      info: { email: 'fallback@example.com', name: nil, preferred_username: 'fallbackuser' }
    )

    user = User.from_omniauth(auth)
    assert_equal 'fallbackuser', user.name
  end

  test "password_required? returns false for OIDC users" do
    user = users(:oidc_user)
    assert_not user.password_required?
  end

  test "password_required? returns true for password users" do
    user = User.new(email: "new@example.com", provider: nil)
    assert user.password_required?
  end
end
