class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    unless current_user.admin?
      flash[:alert] = "관리자만 접근할 수 있습니다."
      redirect_to root_path
    end
  end
end
