# 사용자 디바이스 관리 컨트롤러
class My::DevicesController < ApplicationController
  before_action :set_device, only: [ :update, :destroy ]

  # GET /my/devices
  def index
    @devices = current_user.authorized_devices.recent
    @login_histories = current_user.login_histories.recent.limit(20)
  end

  # PATCH /my/devices/:id
  def update
    if @device.update(device_params)
      redirect_to my_devices_path, notice: "디바이스 이름이 변경되었습니다."
    else
      redirect_to my_devices_path, alert: "디바이스 이름을 변경할 수 없습니다."
    end
  end

  # DELETE /my/devices/:id
  def destroy
    # 현재 사용 중인 디바이스는 삭제 불가
    current_fingerprint = params[:current_fingerprint] || cookies[:device_fingerprint]

    if @device.fingerprint == current_fingerprint
      redirect_to my_devices_path, alert: "현재 사용 중인 디바이스는 삭제할 수 없습니다."
      return
    end

    @device.destroy
    redirect_to my_devices_path, notice: "디바이스가 삭제되었습니다."
  end

  private

  def set_device
    @device = current_user.authorized_devices.find(params[:id])
  end

  def device_params
    params.require(:authorized_device).permit(:device_name)
  end
end
