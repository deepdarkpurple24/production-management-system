class UserMailer < ApplicationMailer
  # 새 사용자 초대 이메일
  def invitation(user, temporary_password)
    @user = user
    @temporary_password = temporary_password
    @login_url = new_user_session_url

    mail(
      to: user.email,
      subject: '[생산관리시스템] 계정이 생성되었습니다'
    )
  end
end
