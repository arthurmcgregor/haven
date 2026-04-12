class Users::SessionsController < Devise::SessionsController
  def new
    if password_login_disabled? && oidc_enabled?
      @oidc_path = omniauth_authorize_path(:user, :openid_connect)
      render 'devise/sessions/oidc_redirect', layout: 'application'
    else
      super
    end
  end

  def create
    if password_login_disabled?
      redirect_to new_user_session_path, alert: "Password login is disabled. Please use SSO."
    else
      super
    end
  end

  private

  def password_login_disabled?
    ENV['HAVEN_DISABLE_PASSWORD_LOGIN'].present?
  end

  def oidc_enabled?
    ENV['HAVEN_OIDC_ISSUER'].present?
  end
end
