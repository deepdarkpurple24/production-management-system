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

    # Store password for invitation email (before it gets encrypted)
    temporary_password = params[:user][:password]

    if @user.save
      # Automatically authorize device for new user
      fingerprint = params[:device_fingerprint]
      device_info = {
        device_name: params[:device_name],
        browser: params[:device_browser],
        os: params[:device_os]
      }

      @user.authorize_device(fingerprint, device_info)

      # Send invitation email with temporary password
      UserMailer.invitation(@user, temporary_password).deliver_now

      flash[:notice] = "사용자가 생성되었습니다. 초대 이메일이 발송되었습니다."
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

    # Prevent changing master admin's admin status
    if @user.email == 'alche0124@gmail.com' && params[:user][:admin] == '0'
      flash[:alert] = "마스터 관리자의 관리자 권한은 변경할 수 없습니다."
      redirect_to edit_admin_user_path(@user)
      return
    end

    if @user.update(user_params)
      flash[:notice] = "사용자 정보가 업데이트되었습니다."
      redirect_to admin_user_path(@user)
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])

    # Prevent deletion of master admin
    if @user.email == 'alche0124@gmail.com'
      flash[:alert] = "마스터 관리자는 삭제할 수 없습니다."
      redirect_to admin_users_path
      return
    end

    # Prevent self-deletion
    if @user == current_user
      flash[:alert] = "자기 자신은 삭제할 수 없습니다."
      redirect_to admin_users_path
      return
    end

    @user.destroy
    flash[:notice] = "사용자가 삭제되었습니다."
    redirect_to admin_users_path
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin, :sub_admin)
  end
end
