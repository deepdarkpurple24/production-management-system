# Preview all emails at http://localhost:3000/rails/mailers/device_mailer
class DeviceMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/device_mailer/authorization_request
  def authorization_request
    DeviceMailer.authorization_request
  end
end
