# 디바이스 승인 컨트롤러
class DeviceAuthorizationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :send_email, :approve ]

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
      ), alert: "사용자를 찾을 수 없습니다."
      return
    end

    # 디바이스 생성 또는 찾기
    device = user.authorized_devices.find_or_initialize_by(fingerprint: params[:fingerprint])
    device.browser = params[:browser]
    device.os = params[:os]
    device.device_name = params[:device_name]
    device.status = "pending"
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
      reason: "새 디바이스 - 이메일 승인 대기 중"
    )

    redirect_to new_user_session_path, notice: "승인 링크가 이메일로 발송되었습니다. 이메일을 확인해주세요."
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
      ), alert: "사용자를 찾을 수 없습니다."
      return
    end

    # 디바이스 생성
    device = user.authorized_devices.find_or_initialize_by(fingerprint: params[:fingerprint])
    device.browser = params[:browser]
    device.os = params[:os]
    device.device_name = params[:device_name]
    device.status = "pending"
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
      reason: "새 디바이스 - 관리자 승인 대기 중"
    )

    # TODO: 관리자에게 알림 이메일 발송
    # AdminMailer.device_approval_request(user, device).deliver_later

    redirect_to new_user_session_path, notice: "관리자에게 승인 요청이 전송되었습니다. 승인 후 로그인할 수 있습니다."
  end

  # GET /device_authorizations/approve?token=xxx
  # 이메일 링크를 통한 디바이스 승인
  def approve
    device = AuthorizedDevice.find_by(authorization_token: params[:token])

    unless device
      render_approval_result(success: false, message: "유효하지 않은 승인 링크입니다.")
      return
    end

    unless device.authorization_token_valid?
      render_approval_result(success: false, message: "승인 링크가 만료되었습니다. (24시간 유효)")
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

    render_approval_result(
      success: true,
      message: "디바이스가 승인되었습니다!",
      user_name: device.user.name || device.user.email,
      device_name: device.device_name
    )
  end

  private

  def render_approval_result(success:, message:, user_name: nil, device_name: nil)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>디바이스 승인 - 생산관리시스템</title>
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }
          .card {
            background: white;
            border-radius: 16px;
            padding: 40px;
            max-width: 400px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
          }
          .icon {
            font-size: 64px;
            margin-bottom: 20px;
          }
          .title {
            font-size: 24px;
            font-weight: 700;
            color: #333;
            margin-bottom: 12px;
          }
          .message {
            font-size: 16px;
            color: #666;
            line-height: 1.6;
            margin-bottom: 24px;
          }
          .device-info {
            background: #f7f7f9;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 24px;
            font-size: 14px;
            color: #555;
          }
          .note {
            font-size: 13px;
            color: #888;
          }
          .success { color: #10b981; }
          .error { color: #ef4444; }
        </style>
      </head>
      <body>
        <div class="card">
          #{success ? '<div class="icon">✅</div>' : '<div class="icon">❌</div>'}
          <div class="title #{success ? 'success' : 'error'}">#{message}</div>
          #{success && user_name ? "<div class=\"device-info\"><strong>#{user_name}</strong>님의<br><strong>#{device_name}</strong> 디바이스</div><div class=\"message\">사용자가 이제 해당 디바이스에서<br>로그인할 수 있습니다.</div>" : '<div class="message">다시 시도하거나 관리자에게 문의하세요.</div>'}
          <div class="note">이 창을 닫아도 됩니다.</div>
        </div>
      </body>
      </html>
    HTML

    render html: html.html_safe, layout: false
  end
end
