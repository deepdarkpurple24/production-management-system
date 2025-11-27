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

    # Handle privileged fields separately (only admins can set these)
    if current_user.admin?
      @user.admin = params[:user][:admin] == "1" if params[:user][:admin].present?
      @user.sub_admin = params[:user][:sub_admin] == "1" if params[:user][:sub_admin].present?
    end

    # Skip email confirmation for admin-created users (they are already vetted)
    @user.skip_confirmation!

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

      # 활동 로그 기록
      log_activity(:create, @user, details: { admin: @user.admin, sub_admin: @user.sub_admin })

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

    # Remove password fields if blank (to avoid Devise validation errors)
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    # Log params for debugging
    Rails.logger.info "=== User Update Debug ==="
    Rails.logger.info "User: #{@user.email}"
    Rails.logger.info "Params: #{params[:user].inspect}"
    Rails.logger.info "Before update - admin: #{@user.admin}, sub_admin: #{@user.sub_admin}"

    # Prevent changing master admin's admin status
    if @user.email == "alche0124@gmail.com" && params[:user][:admin] == "0"
      flash[:alert] = "마스터 관리자의 관리자 권한은 변경할 수 없습니다."
      redirect_to edit_admin_user_path(@user)
      return
    end

    # Handle privileged fields separately (only admins can set these)
    if current_user.admin? && params[:user][:admin].present?
      @user.admin = params[:user][:admin] == "1"
    end

    if current_user.admin? && params[:user][:sub_admin].present?
      @user.sub_admin = params[:user][:sub_admin] == "1"
    end

    if @user.update(user_params)
      Rails.logger.info "After update - admin: #{@user.admin}, sub_admin: #{@user.sub_admin}"

      # 활동 로그 기록
      log_activity(:update, @user, details: { admin: @user.admin, sub_admin: @user.sub_admin })

      flash[:notice] = "사용자 정보가 업데이트되었습니다."
      redirect_to admin_user_path(@user)
    else
      Rails.logger.error "Update failed: #{@user.errors.full_messages.join(', ')}"
      flash.now[:alert] = "저장 실패: #{@user.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])

    # Prevent deletion of master admin
    if @user.email == "alche0124@gmail.com"
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

    # 활동 로그 기록 (삭제 전에 기록)
    log_activity(:destroy, @user, details: { email: @user.email, admin: @user.admin })

    @user.destroy
    flash[:notice] = "사용자가 삭제되었습니다."
    redirect_to admin_users_path
  end

  private

  def user_params
    # Privileged fields (admin, sub_admin) are handled separately in create/update actions
    # to prevent mass assignment security vulnerabilities
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
