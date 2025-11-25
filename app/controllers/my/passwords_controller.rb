# 사용자 비밀번호 변경 컨트롤러
class My::PasswordsController < ApplicationController
  # GET /my/password
  def show
    @user = current_user
  end

  # PATCH /my/password
  def update
    @user = current_user

    # 현재 비밀번호 확인
    unless @user.valid_password?(params[:current_password])
      flash.now[:alert] = '현재 비밀번호가 일치하지 않습니다.'
      render :show
      return
    end

    # 새 비밀번호와 확인 일치 여부
    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = '새 비밀번호와 비밀번호 확인이 일치하지 않습니다.'
      render :show
      return
    end

    # 비밀번호 변경
    if @user.update(password: params[:password])
      # 비밀번호 변경 후 재로그인 필요
      bypass_sign_in(@user)
      redirect_to root_path, notice: '비밀번호가 성공적으로 변경되었습니다.'
    else
      flash.now[:alert] = @user.errors.full_messages.join(', ')
      render :show
    end
  end
end
