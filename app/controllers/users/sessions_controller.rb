# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :check_device_authorization, only: [:create]

  # POST /resource/sign_in
  def create
    fingerprint = params[:device_fingerprint]
    device_info = {
      browser: params[:device_browser],
      os: params[:device_os],
      device_name: params[:device_name]
    }

    # Attempt authentication
    self.resource = warden.authenticate!(auth_options)

    # Check if device is authorized
    unless resource.device_authorized?(fingerprint)
      # Device not authorized
      log_login_attempt(resource, fingerprint, device_info, false, "디바이스가 승인되지 않았습니다")

      sign_out(resource)
      flash[:alert] = "이 디바이스는 승인되지 않았습니다. 관리자에게 문의하세요."
      redirect_to new_user_session_path
      return
    end

    # Device authorized - log success and update last used
    log_login_attempt(resource, fingerprint, device_info, true)

    # Update last used timestamp for the device
    device = resource.authorized_devices.find_by(fingerprint: fingerprint, active: true)
    device&.update_last_used!

    # Complete sign in
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  rescue Warden::NotAuthenticated
    # Authentication failed (wrong password/email)
    fingerprint = params[:device_fingerprint]
    device_info = {
      browser: params[:device_browser],
      os: params[:device_os],
      device_name: params[:device_name]
    }

    # Try to find user by email for logging
    user = User.find_by(email: params.dig(:user, :email))
    log_login_attempt(user, fingerprint, device_info, false, "잘못된 이메일 또는 비밀번호")

    flash[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
    redirect_to new_user_session_path
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  protected

  def check_device_authorization
    unless params[:device_fingerprint].present?
      flash[:alert] = "디바이스 정보를 가져올 수 없습니다. 브라우저를 확인하세요."
      redirect_to new_user_session_path
    end
  end

  def log_login_attempt(user, fingerprint, device_info, success, reason = nil)
    LoginHistory.log_attempt(
      user: user,
      fingerprint: fingerprint,
      ip: request.remote_ip,
      browser: device_info[:browser],
      os: device_info[:os],
      device_name: device_info[:device_name],
      success: success,
      reason: reason
    )
  end
end
