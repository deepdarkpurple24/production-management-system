# 디바이스 승인 컨트롤러
class DeviceAuthorizationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :send_email, :approve]

  # GET /device_authorizations/new
  # 새 디바이스 감지 페이지
  def new
    @fingerprint = params[:fingerprint]
    @device_info = {
      browser: params[:browser],
      os: params[:os],
      device_name: params[:device_name]
    }
    @email = params[:email]
  end

  # POST /device_authorizations/send_email
  # 이메일로 승인 링크 발송
  def send_email
    user = User.find_by(email: params[:email])

    unless user
      redirect_to new_device_authorization_path(
        fingerprint: params[:fingerprint],
        browser: params[:browser],
        os: params[:os],
        device_name: params[:device_name],
        email: params[:email]
      ), alert: '사용자를 찾을 수 없습니다.'
      return
    end

    # 디바이스 생성 또는 찾기
    device = user.authorized_devices.find_or_initialize_by(fingerprint: params[:fingerprint])
    device.browser = params[:browser]
    device.os = params[:os]
    device.device_name = params[:device_name]
    device.status = 'pending'
    device.active = false
    device.save!

    # 승인 토큰 생성
    device.generate_authorization_token!

    # 이메일 발송 (deliver_now for immediate sending)
    DeviceMailer.authorization_request(user, device).deliver_now

    # 로그인 이력 기록
    LoginHistory.log_attempt(
      user: user,
      fingerprint: params[:fingerprint],
      ip: request.remote_ip,
      browser: params[:browser],
      os: params[:os],
      device_name: params[:device_name],
      success: false,
      reason: '새 디바이스 - 이메일 승인 대기 중'
    )

    redirect_to new_user_session_path, notice: '승인 링크가 이메일로 발송되었습니다. 이메일을 확인해주세요.'
  end

  # POST /device_authorizations/request_admin
  # 관리자에게 승인 요청
  def request_admin
    user = User.find_by(email: params[:email])

    unless user
      redirect_to new_device_authorization_path(
        fingerprint: params[:fingerprint],
        browser: params[:browser],
        os: params[:os],
        device_name: params[:device_name],
        email: params[:email]
      ), alert: '사용자를 찾을 수 없습니다.'
      return
    end

    # 디바이스 생성
    device = user.authorized_devices.find_or_initialize_by(fingerprint: params[:fingerprint])
    device.browser = params[:browser]
    device.os = params[:os]
    device.device_name = params[:device_name]
    device.status = 'pending'
    device.active = false
    device.save!

    # 로그인 이력 기록
    LoginHistory.log_attempt(
      user: user,
      fingerprint: params[:fingerprint],
      ip: request.remote_ip,
      browser: params[:browser],
      os: params[:os],
      device_name: params[:device_name],
      success: false,
      reason: '새 디바이스 - 관리자 승인 대기 중'
    )

    # TODO: 관리자에게 알림 이메일 발송
    # AdminMailer.device_approval_request(user, device).deliver_later

    redirect_to new_user_session_path, notice: '관리자에게 승인 요청이 전송되었습니다. 승인 후 로그인할 수 있습니다.'
  end

  # GET /device_authorizations/approve?token=xxx
  # 이메일 링크를 통한 디바이스 승인
  def approve
    device = AuthorizedDevice.find_by(authorization_token: params[:token])

    unless device
      redirect_to new_user_session_path, alert: '유효하지 않은 승인 링크입니다.'
      return
    end

    unless device.authorization_token_valid?
      redirect_to new_user_session_path, alert: '승인 링크가 만료되었습니다. (24시간 유효)'
      return
    end

    # 디바이스 승인
    device.approve!

    # 로그인 이력 업데이트
    LoginHistory.log_attempt(
      user: device.user,
      fingerprint: device.fingerprint,
      ip: request.remote_ip,
      browser: device.browser,
      os: device.os,
      device_name: device.device_name,
      success: true,
      reason: nil
    )

    redirect_to new_user_session_path, notice: '디바이스가 승인되었습니다. 이제 로그인할 수 있습니다.'
  end
end
