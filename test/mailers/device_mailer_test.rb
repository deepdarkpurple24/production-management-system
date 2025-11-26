require "test_helper"

class DeviceMailerTest < ActionMailer::TestCase
  test "authorization_request" do
    user = users(:one)
    device = authorized_devices(:one)

    mail = DeviceMailer.authorization_request(user, device)

    assert_match /새 디바이스 승인 요청/, mail.subject
    assert_equal user.email, mail.to.first
    assert_match user.name, mail.body.encoded
  end
end
