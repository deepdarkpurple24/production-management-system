class DeviceMailer < ApplicationMailer
  # 디바이스 승인 요청 이메일 (관리자에게 발송)
  def authorization_request(user, device)
    @user = user
    @device = device
    @approval_url = approve_device_authorizations_url(token: device.authorization_token)

    # 모든 관리자에게 이메일 발송
    admin_emails = User.where(admin: true).pluck(:email)

    mail(
      to: admin_emails,
      subject: "[생산관리시스템] #{user.name || user.email}님의 새 디바이스 승인 요청"
    )
  end
end
