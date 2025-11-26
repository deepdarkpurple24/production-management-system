class Admin::LoginHistoriesController < Admin::BaseController
  def index
    @filter = params[:filter] || "all"

    @login_histories = LoginHistory.includes(:user).recent

    case @filter
    when "successful"
      @login_histories = @login_histories.successful
    when "failed"
      @login_histories = @login_histories.failed
    when "today"
      @login_histories = @login_histories.today
    when "this_week"
      @login_histories = @login_histories.this_week
    end

    @login_histories = @login_histories.page(params[:page]).per(50) if defined?(Kaminari)

    # Statistics
    @total_attempts = LoginHistory.count
    @successful_attempts = LoginHistory.successful.count
    @failed_attempts = LoginHistory.failed.count
    @today_attempts = LoginHistory.today.count
  end
end
