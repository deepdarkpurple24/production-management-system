# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :block_new_registrations, only: [:new, :create]

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    build_resource(sign_up_params)

    # First user becomes admin automatically
    if User.count.zero?
      resource.admin = true
    end

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        # Automatically authorize device for new user
        fingerprint = params[:device_fingerprint]
        device_info = {
          device_name: params[:device_name],
          browser: params[:device_browser],
          os: params[:device_os]
        }

        resource.authorize_device(fingerprint, device_info)

        # Log successful registration
        LoginHistory.log_attempt(
          user: resource,
          fingerprint: fingerprint,
          ip: request.remote_ip,
          browser: device_info[:browser],
          os: device_info[:os],
          device_name: device_info[:device_name],
          success: true,
          reason: "회원가입 성공"
        )

        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  # Block new registrations if not first user and not admin
  def block_new_registrations
    # Allow if this is the first user (will become admin)
    return if User.count.zero?

    # Block if user is not signed in or not admin
    unless user_signed_in? && current_user.admin?
      flash[:alert] = "신규 회원가입은 관리자만 할 수 있습니다."
      redirect_to new_user_session_path
    end
  end
end
