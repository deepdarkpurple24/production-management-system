require "test_helper"

class DeviceMailerTest < ActionMailer::TestCase
  test "authorization_request" do
    user = users(:one)
    device = authorized_devices(:one)

    mail = DeviceMailer.authorization_request(user, device)

    # Check subject
    assert_match /새 디바이스 승인 요청/, mail.subject
    assert_match user.name, mail.subject

    # Check recipients (should be sent to admins)
    admin_emails = User.where(admin: true).pluck(:email)
    assert_equal admin_emails.sort, mail.to.sort

    # Check that mail has content (body is base64 encoded)
    assert_not_nil mail.body
  end
end
