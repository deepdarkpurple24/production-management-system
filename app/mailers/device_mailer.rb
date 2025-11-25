class DeviceMailer < ApplicationMailer
  # 디바이스 승인 요청 이메일
  def authorization_request(user, device)
    @user = user
    @device = device
    @approval_url = approve_device_authorizations_url(token: device.authorization_token)

    mail(
      to: user.email,
      subject: '[생산관리시스템] 새 디바이스 승인 요청'
    )
  end
end
