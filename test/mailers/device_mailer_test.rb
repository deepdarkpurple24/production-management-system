require "test_helper"

class DeviceMailerTest < ActionMailer::TestCase
  test "authorization_request" do
    mail = DeviceMailer.authorization_request
    assert_equal "Authorization request", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
