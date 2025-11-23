class Admin::AuthorizedDevicesController < Admin::BaseController
  def index
    @authorized_devices = AuthorizedDevice.includes(:user).recent
  end

  def create
    @user = User.find(params[:user_id])
    fingerprint = params[:fingerprint]

    device_info = {
      device_name: params[:device_name],
      browser: params[:browser],
      os: params[:os]
    }

    @user.authorize_device(fingerprint, device_info)

    flash[:notice] = "디바이스가 승인되었습니다."
    redirect_to admin_user_path(@user)
  end

  def destroy
    @device = AuthorizedDevice.find(params[:id])
    @user = @device.user

    @device.destroy

    flash[:notice] = "디바이스 승인이 취소되었습니다."
    redirect_to admin_user_path(@user)
  end

  def toggle_active
    @device = AuthorizedDevice.find(params[:id])

    @device.update(active: !@device.active)

    flash[:notice] = @device.active ? "디바이스가 활성화되었습니다." : "디바이스가 비활성화되었습니다."
    redirect_to admin_user_path(@device.user)
  end
end
