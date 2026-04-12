class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def openid_connect
    @user = User.from_omniauth(request.env['omniauth.auth'])
    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: 'OIDC') if is_navigational_format?
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.error "OIDC auth failed: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    redirect_to new_user_session_path, alert: "Could not authenticate via OIDC: #{e.message}"
  end

  def failure
    redirect_to new_user_session_path, alert: "OIDC authentication failed: #{failure_message}"
  end
end
