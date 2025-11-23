class Admin::UsersController < Admin::BaseController
  def index
    @users = User.all.order(created_at: :desc)
  end

  def show
    @user = User.find(params[:id])
    @authorized_devices = @user.authorized_devices.recent
    @login_histories = @user.login_histories.recent.limit(50)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    # Get device info for auto-authorization
    fingerprint = params[:device_fingerprint]
    device_info = {
      device_name: params[:device_name],
      browser: params[:device_browser],
      os: params[:device_os]
    }

    if @user.save
      # Auto-authorize current device for new user
      @user.authorize_device(fingerprint, device_info)

      flash[:notice] = "사용자가 생성되었습니다."
      redirect_to admin_user_path(@user)
    else
      render :new
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      flash[:notice] = "사용자 정보가 업데이트되었습니다."
      redirect_to admin_user_path(@user)
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])

    # Prevent self-deletion
    if @user == current_user
      flash[:alert] = "자기 자신은 삭제할 수 없습니다."
      redirect_to admin_users_path
      return
    end

    # Prevent deletion of last admin
    if @user.admin? && User.admins.count == 1
      flash[:alert] = "마지막 관리자는 삭제할 수 없습니다."
      redirect_to admin_users_path
      return
    end

    @user.destroy
    flash[:notice] = "사용자가 삭제되었습니다."
    redirect_to admin_users_path
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin)
  end
end
