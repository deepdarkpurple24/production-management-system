# 관리자 활동 로그 컨트롤러
class Admin::ActivityLogsController < ApplicationController
  before_action :require_admin

  PER_PAGE = 50

  def index
    @activity_logs = ActivityLog
      .includes(:user)
      .order(performed_at: :desc)

    # 필터링
    if params[:user_id].present?
      @activity_logs = @activity_logs.where(user_id: params[:user_id])
    end

    if params[:action_type].present?
      @activity_logs = @activity_logs.where(action: params[:action_type])
    end

    if params[:target_type].present?
      @activity_logs = @activity_logs.where(target_type: params[:target_type])
    end

    if params[:date].present?
      date = Date.parse(params[:date])
      @activity_logs = @activity_logs.where(performed_at: date.beginning_of_day..date.end_of_day)
    end

    # 간단한 페이지네이션
    @page = (params[:page] || 1).to_i
    @total_count = @activity_logs.count
    @total_pages = (@total_count / PER_PAGE.to_f).ceil
    @activity_logs = @activity_logs.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)

    # 필터 옵션용 데이터
    @users = User.order(:name)
    @target_types = ActivityLog::TARGET_TYPES
  end

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "관리자만 접근할 수 있습니다."
    end
  end
end
